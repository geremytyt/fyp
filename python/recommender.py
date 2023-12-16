# import pyrebase
# import csv
# import os
# import pandas as pd
# import numpy as np

# config = {
#     "apiKey": "AIzaSyCba4pMD9RmyL-GDMHdYGy10DqmmjAiePI",
#     "authDomain": "com.example.my_travel_mate",
#     "databaseURL": "https://fyp-mytravelmate-default-rtdb.asia-southeast1.firebasedatabase.app/",
#     "projectId": "fyp-mytravelmate",
#     "storageBucket": "gs://fyp-mytravelmate.appspot.com",
#     "appId": "1:247900861989:android:0e47ea0fec99cad5a971cc"
# }

# firebase = pyrebase.initialize_app(config)

# # Get a reference to the Realtime Database
# db = firebase.database()

# # Specify the path to your Excel file
# xlsx_file_path = os.path.abspath('C:\\Users\\gerem\\OneDrive\\Desktop\\MyTravelMate\\data\\All_data_cleaned1.xlsx')

# # Read the Excel file into a DataFrame
# df = pd.read_excel(xlsx_file_path)

# # Replace empty strings with numpy.nan
# df.replace('', np.nan, inplace=True)

# # Replace NaN values with a placeholder value
# placeholder_value = -1  # Choose an appropriate placeholder value
# df.fillna(placeholder_value, inplace=True)


# # Iterate over all rows in the DataFrame
# for index, row in df.iterrows():
#     poiID = row.get('poiID', '')
#     poiType = row.get('poiType', '')  # Replace empty string with None
#     poiName = row.get('poiName', '')
#     poiAddress = row.get('poiAddress', '')
#     poiLocation = row.get('poiLocation', '')
#     poiUrl = row.get('poiUrl', '')
#     poiRating = float(row.get('poiRating', 0))  # Convert to float
#     poiPriceRange = row.get('poiPriceRange', '')  
#     poiPrice = float(row.get('poiPrice', 0))  # Convert to float
#     poiPhone = row.get('poiPhone', '')  
#     poiTag = row.get('poiTag', '') 
#     poiOperatingHours = row.get('poiOperatingHours', '')
#     poiDescription = row.get('poiDescription', '')  
#     poiNoOfReviews = int(row.get('poiNoOfReviews',0))
    
#     # Create a reference to the 'poi' node in the Realtime Database
#     poi_ref = db.child('poi')

#     # Add a child node with the poiID as the key
#     poi_ref.child(poiID).set({
#         'poiType': poiType,
#         'poiName': poiName,
#         'poiAddress': poiAddress,
#         'poiLocation': poiLocation,
#         'poiUrl': poiUrl,
#         'poiRating': poiRating,
#         'poiPriceRange': poiPriceRange,
#         'poiPrice': poiPrice,
#         'poiPhone': poiPhone,
#         'poiTag': poiTag,
#         'poiOperatingHours': poiOperatingHours,
#         'poiDescription': poiDescription,
#         'poiNoOfReviews': poiNoOfReviews
#     })

import pyrebase
import csv
import os
import pandas as pd
import numpy as np

config = {
    "apiKey": "AIzaSyCba4pMD9RmyL-GDMHdYGy10DqmmjAiePI",
    "authDomain": "com.example.my_travel_mate",
    "databaseURL": "https://fyp-mytravelmate-default-rtdb.asia-southeast1.firebasedatabase.app/",
    "projectId": "fyp-mytravelmate",
    "storageBucket": "gs://fyp-mytravelmate.appspot.com",
    "appId": "1:247900861989:android:0e47ea0fec99cad5a971cc"
}

firebase = pyrebase.initialize_app(config)

# Get a reference to the Realtime Database
db = firebase.database()

# Specify the path to your Excel file
xlsx_file_path = os.path.abspath('C:\\Users\\gerem\\OneDrive\\Desktop\\MyTravelMate\\data\\All_data_cleaned1.xlsx')

# Read the Excel file into a DataFrame
df = pd.read_excel(xlsx_file_path)

# Replace empty strings with numpy.nan
df.replace('', np.nan, inplace=True)

# Replace NaN values with a placeholder value
placeholder_value = -1  # Choose an appropriate placeholder value
df.fillna(placeholder_value, inplace=True)

# Iterate over all rows in the DataFrame
for index, row in df.iterrows():
    poiID = row.get('poiID', '')
    poiType = row.get('poiType', '')  # Replace empty string with None
    poiName = row.get('poiName', '')
    poiAddress = row.get('poiAddress', '')
    poiLocation = row.get('poiLocation', '')
    poiUrl = row.get('poiUrl', '')
    poiRating = float(row.get('poiRating', 0))  # Convert to float
    poiPriceRange = row.get('poiPriceRange', '')  
    poiPrice = float(row.get('poiPrice', 0))  # Convert to float
    poiPhone = row.get('poiPhone', '')  
    poiTag = row.get('poiTag', '') 
    poiOperatingHours = row.get('poiOperatingHours', '')
    poiDescription = row.get('poiDescription', '')  
    poiNoOfReviews = int(row.get('poiNoOfReviews',0))
    
    # Check if the POI type is "Hotel"
    if poiType.lower() == 'hotel':
        # Use the current poiTag from the DataFrame
        updated_poiTag = poiTag
        
        # Update the 'poi' node in the Realtime Database with the new poiTag
        db.child('poi').child(poiID).update({'poiTag': updated_poiTag})


# Note: Modify the logic inside the if statement based on how you want to update the poiTag for hotels
