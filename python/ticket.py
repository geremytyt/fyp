import csv
import os
from google.cloud import firestore
from datetime import datetime

# Set up your Firestore credentials
# Replace 'path/to/your/serviceAccountKey.json' with the actual path to your JSON key file
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "C:\\Users\\gerem\\OneDrive\\Desktop\\MyTravelMate\\python\\servicekey.json"

# Initialize Firestore client
db = firestore.Client()

def convert_date_format(date_str):
    # Convert the date string from "DD/MM/YYYY" to "YYYY-MM-DD"
    date_obj = datetime.strptime(date_str, '%d/%m/%Y')
    return date_obj.strftime('%Y-%m-%d')

def import_tickets(csv_file_path):
    try:
        # Open the CSV file
        with open(csv_file_path, newline='', encoding='utf-8') as csvfile:
            # Create a CSV reader
            csv_reader = csv.DictReader(csvfile)

            # Iterate through each row in the CSV file
            for row in csv_reader:
                # Convert date format
                row['ticketDate'] = convert_date_format(row['ticketDate'])

                # Convert string values to appropriate types if needed
                row['childTicketPrice'] = float(row['childTicketPrice'])
                row['childTicketQty'] = int(row['childTicketQty'])
                row['adultTicketPrice'] = float(row['adultTicketPrice'])
                row['adultTicketQty'] = int(row['adultTicketQty'])

                # Use ticketID as the document ID when adding to Firestore
                ticket_id = row['ticketID']
                db.collection('ticket').document(ticket_id).set(row)

        print(f'Tickets from {csv_file_path} successfully imported to Firestore')

    except Exception as e:
        print(f'Error importing tickets: {e}')

if __name__ == "__main__":
    # Replace 'your_csv_file.csv' with the path to your CSV file
    csv_file_path = 'C:\\Users\\gerem\\OneDrive\\Desktop\\MyTravelMate\\data\\ticket_data.csv'

    # Call the function to import tickets
    import_tickets(csv_file_path)
