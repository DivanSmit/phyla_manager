import socket
import tkinter as tk
import json

print("######################")
print("RUNNING FRUIT DATA SENDER")
print("######################")

# Function to send the data through the TCP socket
def send_fruit_data():
    try:
        client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_address = ('localhost', 9910) 
        client_socket.connect(server_address)

        # Capture values from the GUI fields
        data = {
            "name": name_entry.get(),
            "fruittype": fruittype_entry.get(),
            "weight": weight_entry.get(),
            "amount": amount_entry.get(),
            "harvestdate": harvestdate_entry.get()
        }

        json_message = json.dumps(data)

        client_socket.send(json_message.encode())
        client_socket.close()

        print(f"Sent: {json_message}")

        # Reset the fields to blank
        name_entry.delete(0, tk.END)
        fruittype_entry.delete(0, tk.END)
        weight_entry.delete(0, tk.END)
        amount_entry.delete(0, tk.END)
        harvestdate_entry.delete(0, tk.END)

    except Exception as e:
        print(f"Error: {e}")

# GUI Setup
root = tk.Tk()
root.title("Fruit Data Sender")

# Creating labels and entry fields for each field
tk.Label(root, text="Name:").pack()
name_entry = tk.Entry(root)
name_entry.pack()

tk.Label(root, text="Fruit Type:").pack()
fruittype_entry = tk.Entry(root)
fruittype_entry.pack()

tk.Label(root, text="Weight:").pack()
weight_entry = tk.Entry(root)
weight_entry.pack()

tk.Label(root, text="Amount:").pack()
amount_entry = tk.Entry(root)
amount_entry.pack()

tk.Label(root, text="Harvest Date (YYYY/MM/DD):").pack()
harvestdate_entry = tk.Entry(root)
harvestdate_entry.pack()

# Pre-populating the fields with sample data
name_entry.insert(0, "1")
fruittype_entry.insert(0, "apple")
weight_entry.insert(0, "12.3")
amount_entry.insert(0, "12")
harvestdate_entry.insert(0, "2024/07/14")

# Send button
button = tk.Button(root, text="Send", command=send_fruit_data)
button.pack(pady=20)

root.mainloop()
