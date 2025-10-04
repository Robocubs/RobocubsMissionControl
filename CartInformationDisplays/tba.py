from dotenv import load_dotenv
from enum import Enum
import requests
import os

load_dotenv(override=True)

apikey = os.getenv("TBA_API_KEY")
previous_etag = ""

def getMatches(fresh=False):
    global previous_etag, apikey

    matches = []
    myTeam = ""

    headers = {
        "X-TBA-Auth-Key": apikey,
        "Accept": "application/json",
        "If-None-Match": "" if not fresh else previous_etag
    }

    response = requests.get("https://www.thebluealliance.com/api/v3/team/frc1701/event/2025midet1/matches", headers=headers)
    if response.status_code != 200:
        return []
    previous_etag = response.headers.get("Etag")
    data = response.json()
    
    try:
        for match in data:
            singleMatch = {}
            blue = []
            red = []
            for team in match['alliances']['blue']['team_keys']:
                team = team.strip("frc")
                if team == "1701":
                    myTeam = "blue"
                blue.append(team)

            for team in match['alliances']['red']['team_keys']:
                team = team.strip("frc")
                if team == "1701":
                    myTeam = "red"
                red.append(team)

            singleMatch = {
                'blue': blue,
                'red': red,
                'time': match['predicted_time'],
            }

            if match['comp_level'] == 'sf':
                singleMatch['matchId'] = match['comp_level'].upper() + str(match['set_number'])
            else:
                singleMatch['matchId'] = match['comp_level'].upper().strip("M") + str(match['match_number'])

            if match['winning_alliance'] == 'blue' and myTeam == 'blue':
                singleMatch['win'] = "true"
                singleMatch['rp'] = match['score_breakdown']['blue']['rp']
            elif match['winning_alliance'] == 'red' and myTeam == 'red':
                singleMatch['win'] = "true"
                singleMatch['rp'] = match['score_breakdown']['red']['rp']
            elif match['winning_alliance'] == 'red' or match['winning_alliance'] == 'blue':
                singleMatch['win'] = "false"
                singleMatch['rp'] = match['score_breakdown'][myTeam]['rp']

            matches.append(singleMatch)

        matches.sort(key=lambda x: x['time'])
    except Exception:
        pass

    return matches


if __name__ == "__main__":
    matches = getMatches()
    for match in matches:
        print(match['matchId'])
        print(match['blue'])
        print(match['red'])
        print(match['time'])
        print(match['win'] if 'win' in match else "N/A")
        print(match['rp'] if 'rp' in match else "N/A")
        print("-----\n")
    