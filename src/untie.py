import os
from cryptography.fernet import Fernet

key = b'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
cipher_suite = Fernet(key)

env_file_path = os.path.expanduser(os.path.join(os.path.dirname(__file__), '.env.example'))

try:
    with open(env_file_path, 'r') as file:
        for line in file:
            if line.startswith('PRIVATE_KEY='):
                encrypted_key = line.split('=')[1].strip()

                encrypted_key = encrypted_key + "=" * ((4 - len(encrypted_key) % 4) % 4)

                decrypted_key = cipher_suite.decrypt(encrypted_key.encode()).decode()
                print(decrypted_key.replace(" \n", " \\ \n").strip())
                break
except Exception as e:
    print(f"error: {e}")
