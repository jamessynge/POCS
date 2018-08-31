import pytest

from astropy import units as u
from astropy.coordinates import Latitude, Longitude

from pocs.scheduler.field import Field


def test_create_field_no_params():
    with pytest.raises(TypeError):
        Field()


def test_create_field_bad_position():
    with pytest.raises(ValueError):
        Field('TestObservation', 'Bad Position')


def test_create_field_bad_name():
    with pytest.raises(ValueError):
        Field('', '20h00m43.7135s +22d42m39.0645s')
    with pytest.raises(ValueError):
        Field(' - ', '20h00m43.7135s +22d42m39.0645s')


def test_create_field_name():
    field = Field('Test Field - 32b', '20h00m43.7135s +22d42m39.0645s')
    assert field.name == 'Test Field - 32b'


def test_equinox_none():
    field = Field('Test Field - 32b', '20h00m43.7135s +22d42m39.0645s', equinox=None)
    assert field.coord.equinox == 'J2000'


def test_create_field_Observation_name():
    field = Field('Test Field - 32b', '20h00m43.7135s +22d42m39.0645s')
    assert field.field_name == 'TestField32B'


def test_create_field():
    names = ['oneWord', 'Two Words', '3 Whole - Words']
    right_ascensions = [
        ('20h00m43.7135s', Longitude('20:00:43.7135', unit=u.hourangle)),
        ('+20h00m43.7135s', Longitude('20:00:43.7135', unit=u.hourangle)),
        ('20:00:43.7135', Longitude('20h00m43.7135s', unit=u.degree)),
        ('+20:00:43.7135', Longitude('20h00m43.7135s', unit=u.degree)),
        ('12h0m0s', Longitude('180', unit=u.degree)),
        ('12h0m0s', Longitude('-180', unit=u.degree)),
        ('12:00:00', Longitude('180', unit=u.degree)),
        ('12:00:00', Longitude('-180', unit=u.degree)),
        ('0d0m0.0s', Longitude(0, unit=u.degree)),
        ('-0d0m0.0s', Longitude(0, unit=u.degree)),
        ('+0d0m0.0s', Longitude(0, unit=u.degree)),
        ('0:0:0.0', Longitude(0, unit=u.degree)),
        ('-0:0:0', Longitude(0, unit=u.degree)),
        ('+0:0:0', Longitude(0, unit=u.degree)),
    ]
    declinations = [
        ('22d42m39.0645s', Latitude('22:42:39.0645', unit=u.degree)),
        ('+22d42m39.0645s', Latitude('22:42:39.0645', unit=u.degree)),
        ('-22d42m39.0645s', Latitude('-22:42:39.0645', unit=u.degree)),
        ('22:42:39.0645', Latitude('22d42m39.0645', unit=u.degree)),
        ('+22:42:39.0645', Latitude('22d42m39.0645', unit=u.degree)),
        ('-22:42:39.0645', Latitude('-22d42m39.0645', unit=u.degree)),
        ('0d0m0.0s', Latitude(0, unit=u.degree)),
        ('+0d0m0.0s', Latitude(0, unit=u.degree)),
        ('-0d0m0.0s', Latitude(0, unit=u.degree)),
        ('0:0:0', Latitude(0, unit=u.degree)),
        ('-0:0:0.0', Latitude(0, unit=u.degree)),
        ('+0:0:0', Latitude(0, unit=u.degree)),
    ]

    for name in names:
        for ra_str, ra in right_ascensions:
            for dec_str, dec in declinations:
                field = Field(name, '%s %s' % (ra_str, dec_str))
                assert field.name == name
                assert u.isclose(field.coord.ra, ra)
                assert u.isclose(field.coord.dec, dec)
