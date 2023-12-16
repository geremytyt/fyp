import pandas as pd
import numpy as np
import firebase_admin
from firebase_admin import credentials, db

# # Fetch the service account key JSON file from the Firebase project settings
# cred = credentials.Certificate("/home/geremytanyentsen/servicekey.json")
# firebase_admin.initialize_app(cred, {'databaseURL': 'https://fyp-mytravelmate-default-rtdb.asia-southeast1.firebasedatabase.app/'})

# # Reference to the 'poi' node in the Realtime Database
# poi_ref = db.reference('poi')

def get_top_rated_poi(poi_ref):
    # Retrieve the data from Firebase
    poi_data = poi_ref.get()

    # Convert the data to a DataFrame
    df = pd.DataFrame.from_dict(poi_data, orient='index')

    # Reset the index and rename the 'index' column to 'poiID'
    df = df.reset_index().rename(columns={'index': 'poiID'})

    # Display the first 5 rows
    print(df.head(5))

    # Convert 'poiRating' to float
    df['poiRating'] = pd.to_numeric(df['poiRating'], errors='coerce')

    # Calculate and display the mean rating without converting to numeric
    C = df['poiRating'].mean(skipna=True)
    print("Mean Rating:", C)

    # Calculate and display the quantile
    m = df['poiNoOfReviews'].quantile(0.9)
    print("Quantile (90%):", m)

    # Filter places based on the quantile
    q_place = df.copy().loc[df['poiNoOfReviews'] >= m]
    print("Filtered Places Shape:", q_place.shape)

    # Define the weighted rating function
    def weighted_rating(x, m=m, C=C):
        v = x['poiNoOfReviews']
        R = x['poiRating']
        # Calculation based on the IMDB formula
        return (v/(v+m) * R) + (m/(m+v) * C)

    # Define a new feature 'score' and calculate its value with `weighted_rating()`
    q_place['score'] = q_place.apply(weighted_rating, axis=1)

    # Sort places based on score
    q_place = q_place.sort_values('score', ascending=False)

    # Display the top 10 places
    print(q_place[['poiID', 'poiName', 'poiNoOfReviews', 'poiRating', 'score']].head(15))

    # Return recommendations 
    recommendations = q_place[['poiID', 'poiName', 'poiNoOfReviews', 'poiRating', 'score']].head(15).to_dict(orient='records')
    return recommendations
