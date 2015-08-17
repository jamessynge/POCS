import os
import yaml
import zmq

from astropy import units as u
from astropy.coordinates import SkyCoord
from astropy.time import Time

from ..utils import *

@has_logger
class AbstractMount(object):

    def __init__(self,
                 config=dict(),
                 commands=dict(),
                 location=None,
                 ):
        """
        Abstract Base class for controlling a mount. This provides the basic functionality
        for the mounts. Sub-classes should override the `initialize` method for mount-specific
        issues as well as any helper methods specific mounts might need.

        Sets the following properies:

            - self.non_sidereal_available = False
            - self.PEC_available = False
            - self.is_initialized = False

        Args:
            config (dict):              Custom configuration passed to base mount. This is usually
                                        read from the main system config.

            commands (dict):            Commands for the telescope. These are read from a yaml file
                                        that maps the mount-specific commands to common commands.

            location (EarthLocation):   An astropy.coordinates.EarthLocation that contains location configuration items
                                        that are usually read from a config file.
        """

        # Create an object for just the mount config items
        self.mount_config = config.get('mount', {})

        # Check the config for required items
        assert self.mount_config.get('port') is not None, self.logger.error(
            'No mount port specified, cannot create mount\n {}'.format(self.mount_config))

        self.config = config

        # setup commands for mount
        self.commands = self._setup_commands(commands)

        # We set some initial mount properties. May come from config
        self.non_sidereal_available = self.mount_config.setdefault('non_sidereal_available', False)
        self.PEC_available = self.mount_config.setdefault('PEC_available', False)

        # Initial states
        self.is_initialized = False
        self._is_slewing = False
        self._is_parked = False
        self._is_tracking = False

        # Set the initial location
        self._location = location

        # Setup our serial connection at the given port
        self.port = self.mount_config.get('port')
        try:
            self.serial = SerialData(port=self.port)
        except err:
            self.serial = None
            self.logger.warning(err)

        # Set initial coordinates
        self._target_coordinates = None
        self._current_coordinates = None
        self._park_coordinates = None

    @property
    def location(self):
        """ The location details for the mount. See `_setup_location_for_mount` in child class """
        return self._location

    @location.setter
    def location(self, location):
        self._location = location
        # If the location changes we need to update the mount
        self._setup_location_for_mount()

    @property
    def is_connected(self):
        """
        Checks the serial connection on the mount to determine if connection is open

        Returns:
            bool: True if there is a serial connection to the mount.
        """
        return self.serial.is_connected

    @property
    def is_parked(self):
        """ Mount park status """
        return self._is_parked

    @is_parked.setter
    def is_parked(self, parked):
        self._is_parked = parked


    def connect(self):
        """
        Connects to the mount via the serial port (self.port).

        Returns:
            bool:   Returns the self.is_connected value which checks the actual
            serial connection.
        """
        self.logger.info('Connecting to mount')

        if self.serial.ser and self.serial.ser.isOpen() is False:
            try:
                self._connect_serial()
            except OSError as err:
                self.logger.error("OS error: {0}".format(err))
            except:
                self.logger.warning('Could not create serial connection to mount.')
                self.logger.warning('NO MOUNT CONTROL AVAILABLE')
                raise error.BadSerialConnection('Cannot create serial connect for mount at port {}'.format(self.port))

        self.logger.debug('Mount connected: {}'.format(self.is_connected))

        return self.is_connected

    def get_target_coordinates(self):
        """
        Gets the RA and Dec for the mount's current target. This does NOT necessarily
        reflect the current position of the mount.

        @retval         astropy.coordinates.SkyCoord
        """

        if self._target_coordinates is None:
            self.logger.info("Target coordinates not set")
        else:
            self.logger.info('Mount target_coordinates: {}'.format(self._target_coordinates))

        return self._target_coordinates

    def set_target_coordinates(self, coords):
        """
        Sets the RA and Dec for the mount's current target. This does NOT necessarily
        reflect the current position of the mount.

        Args:
            coords (SkyCoord):  astropy SkyCoord coordinates

        Returns:
            target_set (bool):  Boolean indicating success
        """
        target_set = False

        # Save the skycoord coordinates
        self._target_coordinates = coords

        # Get coordinate format from mount specific class
        mount_coords = self._skycoord_to_mount_coord(self._target_coordinates)

        # Send coordinates to mount
        try:
            self.serial_query('set_ra', mount_coords[0])
            self.serial_query('set_dec', mount_coords[1])
            target_set = True
        except:
            self.logger.warning("Problem setting mount coordinates")

        return target_set

    def get_current_coordinates(self):
        """
        Reads out the current coordinates from the mount.

        Returns:
            astropy.coordinates.SkyCoord
        """
        self.logger.debug('Getting current mount coordinates')

        mount_coords = self.serial_query('get_coordinates')

        # Turn the mount coordinates into a SkyCoord
        self._current_coordinates = self._mount_coord_to_skycoord(mount_coords)

        return self._current_coordinates

    ### Movement Methods ###

    def slew_to_coordinates(self, coords, ra_rate=None, dec_rate=None):
        """ Slews to given coordinates

        Note:
            Slew rates are not implemented yet.

        Args:
            coords (astropy.SkyCoord):      Coordinates to slew to
            ra_rate (float):                Slew speed - RA tracking rate (in arcsec per
                second, use 15.0 in absence of tracking model).
            dec_rate (float):               Slew speed - Dec tracking rate (in arcsec per
                second, use 0.0 in absence of tracking model).
        """
        assert isinstance(coords, tuple), self.logger.warning('slew_to_coordinates expects RA-Dec coords')

        response = 0

        if not self.is_parked:
            # Set the coordinates
            if self.set_target_coordinates(coords):
                response = self.slew_to_target()
            else:
                self.logger.warning("Could not set target_coordinates")

        return response

    def slew_to_target(self):
        """
        Slews to the current _target_coordinates
        """
        response = 0

        if not self.is_parked:
            assert self._target_coordinates is not None, self.logger.warning("_target_coordinates not set")

            response =  self.serial_query('slew_to_target')

            if response:
                self.logger.debug('Slewing to target')
            else:
                self.logger.warning('Problem with slew_to_target')
        else:
            self.logger.info('Mount is parked')
            
        return response

    def slew_to_home(self):
        """
        Slews the mount to the home position. Note that Home position and Park
        position are not the same thing
        """
        response = 0

        if not self.is_parked:
            response =  self.serial_query('goto_home')

        return response

    def slew_to_zero(self):
        """ Just calls `slew_to_home` """
        self.slew_to_home()


    def park(self):
        """ Slews to the park position and parks the mount.
        """

        self.set_park_coordinates()
        self.set_target_coordinates(self._park_coordinates)

        response = self.serial_query('park')

        if response:
            self.is_parked = True
            self.logger.debug('Slewing to park')
        else:
            self.logger.warning('Problem with slew_to_park')

        return response

    def unpark(self):
        """
        Unparks the mount. Does not do any movement commands
        """

        self.is_parked = False
        response = self.serial_query('unpark')

        if response:
            self.logger.info('Mount unparked')
        else:
            self.logger.warning('Problem with unpark')

        return response

    def set_park_coordinates(self, ha=-165*u.degree, dec=15*u.degree):
        """
        Calculates the RA-Dec for the the park position.

        The RA is calculated from subtracting the desired hourangle from the local sidereal time

        Returns:
            park_skycoord (SkyCoord):  A SkyCoord object representing current parking position
        """

        park_time = Time.now()
        park_time.location = self.location

        ra = park_time.sidereal_time('apparent') - ha

        self._park_coordinates = SkyCoord(ra, dec)

        self.logger.debug("Park Coordinates RA-Dec: {}".format(self._park_coordinates))

    ### Utility Methods ###
    def serial_query(self, cmd, *args):
        """
        Performs a send and then returns response. Will do a translate on cmd first. This should
        be the major serial utility for commands. Accepts an additional args that is passed
        along with the command. Checks for and only accepts one args param.
        """
        assert self.is_initialized, self.logger.warning('Mount has not been initialized')
        assert len(args) <= 1, self.logger.warning('Ignoring additional arguments for {}'.format(cmd))

        params = args[0] if args else None

        self.logger.info('Mount Query & Params: {} {}'.format(cmd, params))

        self.serial.clear_buffer()

        full_command = self._get_command(cmd, params=params)

        self.serial_write(full_command)

        response = self.serial_read()

        return response

    def serial_write(self, string_command):
        """
            Sends a string command to the mount via the serial port. First 'translates'
            the message into the form specific mount can understand
        """
        assert self.is_initialized, self.logger.warning('Mount has not been initialized')

        self.logger.debug("Mount Send: {}".format(string_command))
        self.serial.write(string_command)

    def serial_read(self):
        """
        Reads from the serial connection.
        """
        assert self.is_initialized, self.logger.warning('Mount has not been initialized')

        response = ''

        # while response == '':
        response = self.serial.read()

        self.logger.debug("Mount Read: {}".format(response))

        # Strip the line ending (#) and return
        return response.rstrip('#')

    def check_pier_position(self):
        """
        Gets the current pier position as either East or West
        """
        position = ('East', 'West')

        current_position = position[int(self.serial_query('pier_position'))]

        return current_position

    ### Private Methods ###
    def _setup_commands(self, commands):
        """
        Does any setup for the commands needed for this mount. Mostly responsible for
        setting the pre- and post-commands. We could also do some basic checking here
        to make sure required commands are in fact available.
        """
        self.logger.info('Setting up commands for mount')

        if len(commands) == 0:
            model = self.mount_config.get('model')
            if model is not None:
                conf_file = "{}/conf_files/{}/{}.yaml".format(
                    self.config.get('resources_dir'),
                    'mounts',
                    model
                )

                if os.path.isfile(conf_file):
                    self.logger.info("Loading mount commands file: {}".format(conf_file))
                    try:
                        with open(conf_file, 'r') as f:
                            commands.update(yaml.load(f.read()))
                            self.logger.info("Mount commands updated from {}".format(conf_file))
                    except OSError as err:
                        self.logger.warning(
                            'Cannot load commands config file: {} \n {}'.format(conf_file, err))
                    except:
                        self.logger.warning("Problem loading mount command file")
                else:
                    self.logger.warning("No such config file for mount commands: {}".format(conf_file))

        # Get the pre- and post- commands
        self._pre_cmd = commands.setdefault('cmd_pre', ':')
        self._post_cmd = commands.setdefault('cmd_post', '#')

        self.logger.info('Mount commands set up')
        return commands

    def _connect_serial(self):
        """Gets up serial connection """
        self.logger.info('Making serial connection for mount at {}'.format(self.port))

        self.serial.connect()

        self.logger.info('Mount connected via serial')

    def _get_command(self, cmd, params=''):
        """ Looks up appropriate command for telescope """
        self.logger.debug('Mount Command Lookup: {}'.format(cmd))

        full_command = ''

        # Get the actual command
        cmd_info = self.commands.get(cmd)

        if cmd_info is not None:

            # Check if this command needs params
            if 'params' in cmd_info:
                if params is '':
                    raise error.InvalidMountCommand('{} expects params: {}'.format(cmd, cmd_info.get('params')))

                full_command = "{}{}{}{}".format(self._pre_cmd, cmd_info.get('cmd'), params, self._post_cmd)
            else:
                full_command = "{}{}{}".format(self._pre_cmd, cmd_info.get('cmd'), self._post_cmd)

            self.logger.debug('Mount Full Command: {}'.format(full_command))
        else:
            self.logger.warning('No command for {}'.format(cmd))
            # raise error.InvalidMountCommand('No command for {}'.format(cmd))

        return full_command

    def _get_expected_response(self, cmd):
        """ Looks up appropriate response for command for telescope """
        self.logger.debug('Mount Response Lookup: {}'.format(cmd))

        response = ''

        # Get the actual command
        cmd_info = self.commands.get(cmd)

        if cmd_info is not None:
            response = cmd_info.get('response')
            self.logger.debug('Mount Command Response: {}'.format(response))
        else:
            raise error.InvalidMountCommand('No result for command {}'.format(cmd))

        return response

    ### NotImplemented methods - should be implemented in child classes ###
    def initialize(self):
        raise NotImplementedError

    def status(self):
        """ Gets the mount statys in various ways """
        raise NotImplementedError

    def sync_coordinates(self):
        """
        Takes as input, the actual coordinates (J2000) of the mount and syncs the mount on them.
        Used after a plate solve.
        Once we have a mount model, we would use sync only initially,
        then subsequent plate solves would be used as input to the model.

        Note:
            Note implemented yet.
        """
        raise NotImplementedError()

    def _setup_location_for_mount(self):
        """ Sets the current location details for the mount. """
        raise NotImplementedError

    def _set_zero_position(self):
        """ Sets the current position as the zero (home) position. """
        raise NotImplementedError

    def _mount_coord_to_skycoord(self):
        raise NotImplementedError

    def _skycoord_to_mount_coord(self):
        raise NotImplementedError
