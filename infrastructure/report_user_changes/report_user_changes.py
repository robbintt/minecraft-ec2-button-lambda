''' Report changes in user status to SNS

This module is intended to be run on cron every minute.
'''
from mcstatus import MinecraftServer
import boto3
import json


def get_players(server_ip, server_port="25565"):
    """ Format this information to be consumed in a template
    """
    server = MinecraftServer.lookup(f"{server_ip}:{server_port}")
    status = server.status(retries=1)

    #server_info["playercount"] = status.players.online
    #server_info["latency"] = status.latency

    if status.players.sample is not None:
        player_names = [player.name for player in status.players.sample]
    else:
        player_names = []

    return player_names

def main():
    ''' Report any change in cached players to SNS

    This is intended to update every second on cron.
    NB: debounce should be used in the SNS notifier to avoid excess messages.
    '''
    server_host = 'localhost'
    last_players_file = 'players_online.dat'
    sns_arn = ''

    with open(last_players_file) as f:
        last_player_names = json.load(f)

    player_names = get_players(server_host)

    just_logged_in = set(player_names) - set(last_player_names)
    just_logged_out = set(last_player_names) - set(player_names)

    # TODO: optional local json map to attach realnames to usernames in message content

    messages = []
    for player in just_logged_in:
        messages.append({'text': f"{player} has joined Cincicraft!"})
    for player in just_logged_out:
        messages.append({'text': f"{player} has left Cincicraft."})

    client = boto3.client('sns')
    for message in messages:
        response = client.publish(
            TargetArn=sns_arn,
            Message=json.dumps(message))
        print(response)

if __name__ == '__main__':
    main()
