import socket
import tkinter as tk
import random

# Function to send a random number through the TCP socket
def send_random_number():
    try:
        client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_address = ('localhost', 9910) 
        client_socket.connect(server_address)

        random_number = random.randint(1, 6)

        client_socket.send(str(random_number).encode())
        client_socket.close()

    except Exception as e:
        print(f"Error: {e}")

root = tk.Tk()
root.title("Random Number Sender")

button = tk.Button(root, text="Send Random Number", command=send_random_number)
button.pack(pady=20)

root.mainloop()
