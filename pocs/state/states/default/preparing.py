def on_enter(event_data):
    """Pointing State

    Take 30 second exposure and plate-solve to get the pointing error
    """
    pocs = event_data.model

    pocs.next_state = 'parking'

    try:
        pocs.say("Preparing the observations for our selected target")

        # TODO

    except Exception as e:
        pocs.logger.warning("Problem with preparing: {}".format())
