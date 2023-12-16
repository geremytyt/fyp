import json
import requests
import firebase_admin
from firebase_admin import credentials, db
import pandas as pd


# cred = credentials.Certificate("/home/geremytanyentsen/servicekey.json")
# firebase_admin.initialize_app(cred, {'databaseURL': 'https://fyp-mytravelmate-default-rtdb.asia-southeast1.firebasedatabase.app/'})

# # Reference to the database
# ref = db.reference('/poi')

import googlemaps

# Replace 'YOUR_API_KEY' with your actual Google Maps API key
gmaps = googlemaps.Client(key='AIzaSyDz9pepBSYg90CZXK1WZkucemlJxlSinuY')

# Function to geocode using Google Maps API
def geocode(address):
    try:
        # Geocode the address to get the location
        location = gmaps.geocode(address)[0]
        lat, lng = location['geometry']['location'].get('lat'), location['geometry']['location'].get('lng')
        return lat, lng
    except Exception as e:
        print(f"Error geocoding {address}: {e}")
        return None, None

# Read CSV file into a DataFrame
csv_file_path = 'C:\\Users\\gerem\\OneDrive\\Desktop\\MyTravelMate\\data\\poi.csv'
df = pd.read_csv(csv_file_path)

# Iterate through rows and update latitude and longitude
for index, row in df.iterrows():
    name = row['poiName']
    address = row['poiAddress']
    location = row['poiLocation']
    lat = row['poiLatitude']
    lng = row['poiLongitude']
    
    # Check if poiLatitude and poiLongitude are null
    if pd.isna(lat) or pd.isna(lng):
        # Use poiLocation if available, otherwise use poiName
        query = location if pd.notna(location) else name
        
        # Geocode using the chosen query to get latitude and longitude
        lat, lng = geocode(query)
        
        # Update DataFrame with the retrieved latitude and longitude
        df.at[index, 'poiLatitude'] = lat
        df.at[index, 'poiLongitude'] = lng

# # Function to get latitude and longitude from Google Maps API
# def get_lat_lng(name, address, location):
#     try:
#         # Combine poiName, poiAddress, and poiLocation for a more accurate result
#         if address != -1:
#             query = f"{name}, {address}"
#         elif address ==-1 and location != -1:
#             query = f"{name}, {location}"
#         else:
#             query = name
        
#         # Geocode the combined query
#         geocode_result = gmaps.geocode(query)
        
#         # Extract latitude and longitude
#         location = geocode_result[0]['geometry']['location']
#         return location['lat'], location['lng']
#     except Exception as e:
#         print(f"Error geocoding {name}, {address}, {location}: {e}")
#         return None, None

# # Read CSV file into a DataFrame
# csv_file_path = 'C:\\Users\\gerem\\OneDrive\\Desktop\\MyTravelMate\\data\\poi.csv'
# df = pd.read_csv(csv_file_path)

# # Iterate through rows and update latitude and longitude
# for index, row in df.iterrows():
#     name = row['poiName']
#     address = row['poiAddress']
#     location = row['poiLocation']
    
#     # Get latitude and longitude from Google Maps API
#     lat, lng = get_lat_lng(name, address, location)
    
#     # Update DataFrame with latitude and longitude
#     df.at[index, 'poiLatitude'] = lat
#     df.at[index, 'poiLongitude'] = lng


# Save the updated DataFrame back to CSV with an absolute path
df.to_csv('C:\\Users\\gerem\\OneDrive\\Desktop\\MyTravelMate\\data\\poi_updated.csv', index=False)

# # Function to delete specified fields under each poiID node
# def delete_fields(poi_id):
#     try:
#         poi_ref = ref.child(poi_id)
#         poi_ref.child('address').delete()
#         poi_ref.child('coordinates').delete()
#         print(f"Fields deleted for poiID: {poi_id}")
#     except Exception as e:
#         print(f"Error deleting fields for poiID {poi_id}: {e}")

# # Get a list of all poiIDs
# poi_ids = ref.get().keys()

# # Delete fields for each poiID
# for poi_id in poi_ids:
#     delete_fields(poi_id)

# def update_coordinates(api_key, poi_data):
#     geocoding_endpoint = 'https://maps.googleapis.com/maps/api/geocode/json'

#     for poi_id, poi_info in poi_data.items():
#         poi_name = poi_info['poiName']

#         # Step 1: Perform geocoding request
#         response = requests.get(f'{geocoding_endpoint}?address={poi_name}&key={api_key}')
#         data = response.json()

#         # Step 2: Process geocoding response
#         if response.status_code == 200 and data.get('status') == 'OK':
#             locations = data['results']
            
#             # Step 3: Update latitude, longitude, and address for each location in Firebase Realtime Database
#             coordinates = []
#             addresses = []
#             for idx, location in enumerate(locations, start=1):
#                 latitude, longitude = location['geometry']['location']['lat'], location['geometry']['location']['lng']
#                 address = location['formatted_address']
                
#                 coordinates.append({'latitude': latitude, 'longitude': longitude})
#                 addresses.append(address)

#             # Update 'coordinates' and 'address' fields in Firebase Realtime Database
#             poi_ref = db.reference(f'poi/{poi_id}')
#             poi_ref.update({'coordinates': coordinates, 'address': addresses})

#             print(f'Data for {poi_id}: Coordinates - {coordinates}, Address - {addresses} stored in the database')

#         else:
#             print(f'Error processing geocoding for {poi_id}')

# def update_coordinates(api_key, poi_data):
#     geocoding_endpoint = 'https://maps.googleapis.com/maps/api/geocode/json'

#     for poi_id, poi_info in poi_data.items():
#         # Check if 'coordinates' and 'address' fields already exist
#         if 'coordinates' in poi_info and 'address' in poi_info:
#             continue  # Skip if coordinates and address are already present
        
#         poi_address = poi_info.get('poiAddress', '')

#         # Step 1: Perform geocoding request using poiAddress
#         response = requests.get(f'{geocoding_endpoint}?address={poi_address}&key={api_key}')
#         data = response.json()

#         # Step 2: Process geocoding response
#         if response.status_code == 200 and data.get('status') == 'OK':
#             locations = data['results']
            
#             # Step 3: Update latitude, longitude, and address in Firebase Realtime Database
#             coordinates = []
#             addresses = []
#             for idx, location in enumerate(locations, start=1):
#                 latitude, longitude = location['geometry']['location']['lat'], location['geometry']['location']['lng']
#                 address = location['formatted_address']
                
#                 coordinates.append({'latitude': latitude, 'longitude': longitude})
#                 addresses.append(address)

#             # Update 'coordinates' and 'address' fields in Firebase Realtime Database
#             poi_ref = db.reference(f'poi/{poi_id}')
#             poi_ref.update({'coordinates': coordinates, 'address': addresses})

#             print(f'Data for {poi_id}: Coordinates - {coordinates}, Address - {addresses} stored in the database')

#         else:
#             print(f'Error processing geocoding for {poi_id}')

# def update_coordinates(api_key, poi_data):
#     geocoding_endpoint = 'https://maps.googleapis.com/maps/api/geocode/json'

#     for poi_id, poi_info in poi_data.items():
#         # Check if 'coordinates' and 'address' fields already exist
#         if 'coordinates' in poi_info and 'address' in poi_info:
#             continue  # Skip if coordinates and address are already present
        
#         poi_name = poi_info.get('poiName', '')
#         poi_location = poi_info.get('poiLocation', '')

#         # Combine poiName and poiLocation for geocoding
#         query = f'{poi_name}, {poi_location}'

#         # Step 1: Perform geocoding request using combined query
#         response = requests.get(f'{geocoding_endpoint}?address={query}&key={api_key}')
#         data = response.json()

#         # Step 2: Process geocoding response
#         if response.status_code == 200 and data.get('status') == 'OK':
#             locations = data['results']
            
#             # Step 3: Update latitude, longitude, and address in Firebase Realtime Database
#             coordinates = []
#             addresses = []
#             for idx, location in enumerate(locations, start=1):
#                 latitude, longitude = location['geometry']['location']['lat'], location['geometry']['location']['lng']
#                 address = location['formatted_address']
                
#                 coordinates.append({'latitude': latitude, 'longitude': longitude})
#                 addresses.append(address)

#             # Update 'coordinates' and 'address' fields in Firebase Realtime Database
#             poi_ref = db.reference(f'poi/{poi_id}')
#             poi_ref.update({'coordinates': coordinates, 'address': addresses})

#             print(f'Data for {poi_id}: Coordinates - {coordinates}, Address - {addresses} stored in the database')

#         else:
#             print(f'Error processing geocoding for {poi_id}')


# if __name__ == "__main__":
#     google_maps_api_key = 'AIzaSyDz9pepBSYg90CZXK1WZkucemlJxlSinuY'
    
#     # Fetch POI data from Firebase Realtime Database
#     poi_ref = db.reference('poi')
#     poi_data_snapshot = poi_ref.get()
    
#     if poi_data_snapshot:
#         poi_data = poi_data_snapshot
#         update_coordinates(google_maps_api_key, poi_data)
#     else:
#         print('No POI data found in the database.')
