import requests
import sys

if len(sys.argv) != 2:
    sys.exit("Usage: python script.py <EVM Address>")

address = sys.argv[1]

url = f"https://openapiv1.coinstats.app/wallet/balances?address={address}&networks=all"

headers = {
    "accept": "application/json",
    "X-API-KEY": "rlYfi/vLmMSpnp1TH0LZM5RecpK82/2XPwoM8ZkEU2k="
}

try:
    response = requests.get(url, headers=headers)
    response.raise_for_status()

    data = response.json()
    
    total_value = 0
    for entry in data if isinstance(data, list) else [data]:
        balances = entry.get("balances", [])
        for item in balances:
            amount = item.get("amount", 0)
            price = item.get("price", 0)
            total_value += amount * price

    print(f"{total_value:.2f}")

except requests.RequestException as e:
    sys.exit(f"Network error: {e}")

except ValueError:
    sys.exit("Error parsing data, please check the API response.")
