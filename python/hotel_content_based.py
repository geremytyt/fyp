import numpy as np
import pandas as pd
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import MinMaxScaler
from sklearn.feature_extraction.text import TfidfVectorizer
import firebase_admin
from firebase_admin import credentials, db


# Function to initialize Firebase app
def initialize_firebase_app():
    cred = credentials.Certificate("/home/geremytanyentsen/servicekey.json")
    firebase_admin.initialize_app(cred, {'databaseURL': 'https://fyp-mytravelmate-default-rtdb.asia-southeast1.firebasedatabase.app/'})


def recommend_hotel_content_based(name):

    # Initialize Firebase app (call this function only if it hasn't been initialized)
    if not firebase_admin._apps:
        initialize_firebase_app()
        
    # Reference to the 'poi' node in the Realtime Database
    poi_ref = db.reference('poi')

    # Retrieve data from Firebase Realtime Database
    poi_data = poi_ref.get()

    # Convert the data to a DataFrame
    poi_data_df = pd.DataFrame.from_dict(poi_data, orient='index')

    # Set the index to 'poiName'
    poi_data_df.set_index('poiName', inplace=True)

    # Create a series of the POI names
    poi_indices = pd.Series(poi_data_df.index)

    poi_data_df['poiPrice'].fillna(0, inplace=True)
    poi_data_df['poiRating'].fillna(0, inplace=True)
    poi_data_df['poiTag'] = poi_data_df['poiTag'].replace(-1, '')
    poi_data_df['poiTag'].fillna('', inplace=True)

    # Creating tf-idf matrix based on 'poiTag'
    tfidf = TfidfVectorizer(analyzer='word', ngram_range=(1, 2), stop_words='english', min_df=1)
    tfidf_matrix = tfidf.fit_transform(poi_data_df['poiTag'])

    # Find the index of the POI entered
    idx = poi_indices[poi_indices == name].index[0]
    
    # Extract 'poiPrice' and 'poiRating' for the selected POI
    selected_poi = poi_data_df.loc[name, ['poiPrice', 'poiRating']].values.reshape(1, -1)
    
    # Extract 'poiPrice' and 'poiRating' for all POIs
    all_pois = poi_data_df[['poiPrice', 'poiRating']].values
    
    # Normalize the values using Min-Max scaling
    scaler = MinMaxScaler()
    all_pois_scaled = scaler.fit_transform(all_pois)
    selected_poi_scaled = scaler.transform(selected_poi)
    
    # Calculate cosine similarities based on 'poiPrice' and 'poiRating'
    cosine_similarities = cosine_similarity(selected_poi_scaled, all_pois_scaled)

    # Calculate cosine similarities based on 'poiTag'
    tag_cosine_similarities = cosine_similarity(tfidf_matrix[idx], tfidf_matrix).flatten()
    
    # Combine the cosine similarities
    final_cosine_similarities = 0.7 * cosine_similarities[0] + 0.3 * tag_cosine_similarities
    
    # Find the POIs with similar cosine-sim value and order them from the biggest number
    score_series = pd.Series(final_cosine_similarities).sort_values(ascending=False)
    
    # Extract top 10 POI indexes with similar cosine-sim value
    top10_indexes = list(score_series.iloc[0:11].index)
    
    # Retrieve the name of the top 10 similar POIs based on their indexes
    recommend_pois = [list(poi_data_df.index)[each] for each in top10_indexes if list(poi_data_df.index)[each] != name]
    
    # Create a new DataFrame and populate it with information from the poi_data DataFrame for each of the recommended POIs
    df_new = pd.DataFrame(columns=['poiID', 'poiType', 'poiTag', 'poiPrice', 'poiRating', 'cosine similarity', 'poiName'])

    for each in recommend_pois:
        cosine_similarity_value = final_cosine_similarities[list(poi_data_df.index).index(each)]
        temp_df = pd.DataFrame(poi_data_df[['poiID', 'poiType', 'poiTag', 'poiPrice', 'poiRating']][poi_data_df.index == each]
                                .assign(**{'cosine similarity': cosine_similarity_value, 'poiName': each}))
        df_new = pd.concat([df_new, temp_df], ignore_index=True)

    # Drop the same named POIs and sort only the top 10 by the highest rating
    df_new = df_new.drop_duplicates(subset=['poiName'], keep='first')
    df_new = df_new.sort_values(by=['cosine similarity', 'poiRating'], ascending=[False, False]).head(10)

    print('TOP %s POIs LIKE %s WITH SIMILAR Price, Rating, and Tags: ' % (str(len(df_new)), name))

    return df_new.to_dict(orient='records')

