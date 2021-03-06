import os
import pytest

from astropy.coordinates import EarthLocation

from pocs.core import POCS
from pocs.dome.bisque import Dome
from pocs.utils import altaz_to_radec
from pocs.utils import current_time
from pocs.utils.config import load_config
from pocs.utils.theskyx import TheSkyX


pytestmark = pytest.mark.skipif(TheSkyX().is_connected is False,
                                reason="TheSkyX is not connected")


@pytest.fixture
def location():
    config = load_config(ignore_local=False)
    loc = config['location']
    return EarthLocation(lon=loc['longitude'], lat=loc['latitude'], height=loc['elevation'])


@pytest.fixture
def target(location):
    return altaz_to_radec(obstime=current_time(), location=location, alt=45, az=90)


@pytest.fixture
def target_down(location):
    return altaz_to_radec(obstime=current_time(), location=location, alt=5, az=90)


@pytest.fixture
def pocs(target):
    try:
        del os.environ['POCSTIME']
    except KeyError:
        pass

    config = load_config(ignore_local=False)

    pocs = POCS(simulator=['weather', 'night', 'camera'], run_once=True,
                config=config, db='panoptes_testing', messaging=True)

    pocs.observatory.scheduler.fields_list = [
        {'name': 'Testing Target',
         'position': target.to_string(style='hmsdms'),
         'priority': '100',
         'exp_time': 2,
         'min_nexp': 2,
         'exp_set_size': 2,
         },
    ]

    yield pocs

    pocs.power_down()


@pytest.fixture(scope="function")
def dome():
    try:
        del os.environ['POCSTIME']
    except KeyError:
        pass

    dome = Dome()
    yield dome


def test_pocs_run(pocs, dome):
    assert dome.connect() is True
    dome.open_slit()
    assert dome.is_open is True

    pocs.state = 'sleeping'
    pocs._do_states = True

    pocs.initialize()
    assert pocs.is_initialized is True

    pocs.run(exit_when_done=True, run_once=True)
    assert pocs.state == 'sleeping'

    dome.close_slit()
    dome.disconnect()
    assert dome.is_connected is False
