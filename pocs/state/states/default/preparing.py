from astropy import units as u


def on_enter(event_data):
    """Pointing State

    Take 30 second exposure and plate-solve to get the pointing error
    """
    pocs = event_data.model

    pocs.next_state = 'parking'

    try:
        pocs.say("Preparing the observations for our selected target")

        current_observation = pocs.observatory.current_observation

        if pocs.observatory.has_hdr_mode:

            pocs.logger.debug("Getting exposure times from imager array")

            # Generating a list of exposure times for the imager array
            exp_times = pocs.observatory.imager_array.exposure_time_array(
                minimum_magnitude=10 * u.ABmag,
                num_longexp=1,
                factor=2,
                maximum_exptime=300 * u.second,
                maximum_magnitude=20 * u.ABmag
            )
            pocs.say("Exposure times: {}".format(exp_times))

            pocs.next_state = 'slewing'

    except Exception as e:
        pocs.logger.warning("Problem with preparing: {}".format())
