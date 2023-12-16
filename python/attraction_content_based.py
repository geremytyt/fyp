import numpy as np
import pandas as pd
from sklearn.metrics.pairwise import linear_kernel
from sklearn.feature_extraction.text import TfidfVectorizer
import firebase_admin
from firebase_admin import credentials, db

# Function to initialize Firebase app
def initialize_firebase_app():
    cred = credentials.Certificate("/home/geremytanyentsen/servicekey.json")
    firebase_admin.initialize_app(cred, {'databaseURL': 'https://fyp-mytravelmate-default-rtdb.asia-southeast1.firebasedatabase.app/'})

def recommend_attraction_content_based(name):

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

    poi_data_df['poiTag'] = poi_data_df['poiTag'].replace(-1, '')
    poi_data_df['poiTag'].fillna('', inplace=True)

    # Creating tf-idf matrix based on 'poiTag'
    tfidf = TfidfVectorizer(analyzer='word', ngram_range=(1, 2), stop_words='english', min_df=1)
    tfidf_matrix = tfidf.fit_transform(poi_data_df['poiTag'])

    # Calculate cosine similarities based on 'poiTag'
    cosine_similarities = linear_kernel(tfidf_matrix, tfidf_matrix)

    # Find the index of the POI entered
    idx = poi_indices[poi_indices == name].index[0]
    
    # Find the POIs with similar cosine-sim value and order them from the biggest number
    score_series = pd.Series(cosine_similarities[idx]).sort_values(ascending=False)
    
    # Extract top 30 POI indexes with similar cosine-sim value
    top30_indexes = list(score_series.iloc[0:31].index)
    
    # Retrieve the name of the top 30 similar POIs based on their indexes
    recommend_pois = [list(poi_data_df.index)[each] for each in top30_indexes]
    
    # Create a new DataFrame and populate it with information from the poi_data DataFrame for each of the recommended POIs
    df_new = pd.DataFrame(columns=['poiID', 'poiType', 'poiTag', 'poiRating', 'cosine similarity', 'poiName'])

    for each in recommend_pois:
        if each != name:  # Exclude the entered POI
            cosine_similarity = cosine_similarities[idx][list(poi_data_df.index).index(each)]
            temp_df = pd.DataFrame(poi_data_df[['poiID', 'poiType', 'poiTag', 'poiRating']][poi_data_df.index == each]
                                    .assign(**{'cosine similarity': cosine_similarity, 'poiName': each}))
            df_new = pd.concat([df_new, temp_df], ignore_index=True)

    # Drop the same named POIs and sort only the top 10 by the highest rating
    df_new = df_new.drop_duplicates(subset=['poiName'], keep='first')
    df_new = df_new.sort_values(by=['cosine similarity', 'poiRating'], ascending=[False, False]).head(10)
    
    # Filter only the POIs with 'poiType' being 'Attraction'
    df_new = df_new[df_new['poiType'] == 'Attraction']

    print('TOP %s Attractions LIKE %s WITH SIMILAR Type, Tag, and Rating: ' % (str(len(df_new)), name))

    return df_new.to_dict(orient='records')




