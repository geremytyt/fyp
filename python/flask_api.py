from flask import Flask, jsonify, request, send_file, Response
import firebase_admin
from firebase_admin import credentials, db
import csv
from io import StringIO
import pandas as pd
import json
from haversine import haversine, Unit
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import OneHotEncoder
import joblib
from sklearn.metrics.pairwise import linear_kernel
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import MinMaxScaler

app = Flask(__name__)

# Fetch the service account key JSON file from the Firebase project settings
cred = credentials.Certificate("/home/geremytanyentsen/servicekey.json")
firebase_admin.initialize_app(cred, {'databaseURL': 'https://fyp-mytravelmate-default-rtdb.asia-southeast1.firebasedatabase.app/'})

# Reference to the 'poi' node in the Realtime Database
poi_ref = db.reference('poi')

@app.route('/get_demographic_report_data', methods=['GET'])
def get_demographic_report_data():
    try:
        # Replace the path with the correct path to your CSV file
        df = pd.read_csv('/home/geremytanyentsen/user_data.csv', encoding='latin-1')

        # Gender Data Processing
        gender_counts = df['gender'].value_counts()
        total_gender = gender_counts.sum()
        gender_percentage = (gender_counts / total_gender) * 100
        gender_data = gender_percentage.to_dict()

        # Age Data Processing
        # Define age categories or ranges
        age_bins = [0, 18, 25, 35, 45, 55, 65, 100]
        age_labels = ['0-18', '19-25', '26-35', '36-45', '46-55', '56-65', '66+']

        # Create a new 'age_category' column based on age bins
        df['age_category'] = pd.cut(df['age'], bins=age_bins, labels=age_labels, right=False)

        # Count occurrences in each age category
        age_counts = df['age_category'].value_counts().sort_index().to_dict()

        # Convert int64 types to standard Python integers
        gender_data = {key: int64_to_int(value) for key, value in gender_data.items()}
        age_counts = {key: int64_to_int(value) for key, value in age_counts.items()}

        result = {
            'gender_data': {
                'male_percentage': float(gender_data.get('Male', 0)),
                'female_percentage': float(gender_data.get('Female', 0)),
                'total_male': int(gender_counts.get('Male', 0)),
                'total_female': int(gender_counts.get('Female', 0)),
            },
            'age_data': {str(key): int(value) for key, value in age_counts.items()}
        }


        # Print intermediate results for debugging
        print("Gender Data:", gender_data)
        print("Age Data:", age_counts)
        print("Result:", result)

        return Response(json.dumps(result), content_type='application/json; charset=utf-8')

    except Exception as e:
        return jsonify({'error': str(e)}), 500

def int64_to_int(value):
    # Convert int64 to int if necessary
    return int(value) if pd.notna(value) else None

################
#RECOMMENDATIONS
################

@app.route('/recommend_hotel_content_based', methods=['GET'])
def recommend_hotels_content_based():
    poi_name = request.args.get('poiName')
    recommendations = recommend_hotel_content_based(poi_name)
    return jsonify(recommendations)

def recommend_hotel_content_based(name):

    poi_data_df = pd.read_csv(poi_file_path)

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
    all_pois_scaled = scaler.fit_transform(all_pois).reshape(1, -1)  # Reshape to 2D
    selected_poi_scaled = scaler.transform(selected_poi).reshape(1, -1)  # Reshape to 2D

    # Calculate linear kernel based on 'poiPrice' and 'poiRating'
    linear_similarity = linear_kernel(selected_poi_scaled, all_pois)

    # Calculate linear kernel based on 'poiTag'
    tag_linear_similarities = linear_kernel(tfidf_matrix[idx].reshape(1, -1), tfidf_matrix).flatten()

    # Combine the linear similarities
    final_linear_similarities = 0.7 * linear_similarity[0] + 0.3 * tag_linear_similarities
    
    # Find the POIs with similar linear-sim value and order them from the biggest number
    score_series = pd.Series(final_linear_similarities).sort_values(ascending=False)
    
    # Extract top 10 POI indexes with similar linear-sim value
    top10_indexes = list(score_series.iloc[0:11].index)
    
    # Retrieve the name of the top 10 similar POIs based on their indexes
    recommend_pois = [list(poi_data_df.index)[each] for each in top10_indexes if list(poi_data_df.index)[each] != name]

    # Create a list to store DataFrames
    dfs = []

    for each in recommend_pois:
        if each != name:  # Exclude the entered POI
            # Replace cosine_similarity with linear_similarity
            similarity = linear_similarity[idx][list(poi_data_df.index).index(each)]
            temp_df = poi_data_df[['poiID', 'poiType', 'poiTag', 'poiPrice', 'poiRating']][poi_data_df.index == each]
            temp_df['similarity'] = similarity 
            temp_df['poiName'] = each
            dfs.append(temp_df)

    # Concatenate the list of DataFrames
    df_new = pd.concat(dfs, ignore_index=True)
    
    # Drop the same named POIs and sort only the top 10 by the highest rating
    df_new = df_new.drop_duplicates(subset=['poiName'], keep='first')
    df_new = df_new.sort_values(by=['cosine similarity', 'poiRating'], ascending=[False, False]).head(10)

    print('TOP %s POIs LIKE %s WITH SIMILAR Price, Rating, and Tags: ' % (str(len(df_new)), name))

    return {
        "content_based_hotels": df_new.drop(columns=['cosine similarity']).to_dict(orient='records'),
    }

@app.route('/recommend_attraction_content_based', methods=['GET'])
def recommend_attractions_content_based():
    poi_name = request.args.get('poiName')
    recommendations = recommend_attraction_content_based(poi_name)
    return jsonify(recommendations)

def recommend_attraction_content_based(name):
    poi_data = pd.read_csv(poi_file_path)

    # Set the index to 'poiName'
    poi_data.set_index('poiName', inplace=True)

    # Create a series of the POI names
    poi_indices = pd.Series(poi_data.index)

    poi_data['poiTag'] = poi_data['poiTag'].replace(-1, '')
    poi_data['poiTag'].fillna('', inplace=True)

    # Combine 'poiType', 'poiTag', and 'poiRating' into a single string for each POI
    poi_data['combined_features'] = (
        poi_data['poiType'] + ' ' +
        poi_data['poiTag'] + ' ' +
        poi_data['poiRating'].astype(str)
    )

    print("Combined Features:")
    print(poi_data['combined_features'])

    # Creating tf-idf matrix based on 'combined_features'
    tfidf = TfidfVectorizer(analyzer='word', ngram_range=(1, 2), stop_words='english', min_df=1)
    tfidf_matrix = tfidf.fit_transform(poi_data['combined_features'])

    # Print the TF-IDF matrix for debugging
    print("\nTF-IDF Matrix:")
    print(tfidf_matrix)

    # Calculate cosine similarities based on 'combined_features'
    cosine_similarities = linear_kernel(tfidf_matrix, tfidf_matrix)

    # Find the index of the POI entered
    idx = poi_indices[poi_indices == name].index[0]

    # Find the POIs with similar cosine-sim value and order them from the biggest number
    score_series = pd.Series(cosine_similarities[idx]).sort_values(ascending=False)

    # Extract top 10 POI indexes with similar cosine-sim value
    top10_indexes = list(score_series.iloc[0:11].index)

    # Retrieve the name of the top 10 similar POIs based on their indexes
    recommend_pois = [list(poi_data.index)[each] for each in top10_indexes]

    # Create a list to store DataFrames
    dfs = []

    for each in recommend_pois:
        if each != name:  # Exclude the entered POI
            cosine_similarity = cosine_similarities[idx][list(poi_data.index).index(each)]
            temp_df = poi_data[['poiID', 'poiType', 'poiTag', 'poiRating']][poi_data.index == each]
            temp_df['cosine similarity'] = cosine_similarity
            temp_df['poiName'] = each
            dfs.append(temp_df)

    # Concatenate the list of DataFrames
    df_new = pd.concat(dfs, ignore_index=True)

    # Drop the same named POIs and sort only the top 10 by the highest rating
    df_new = df_new.drop_duplicates(subset=['poiName'], keep='first')
    df_new = df_new.sort_values(by=['cosine similarity', 'poiRating'], ascending=[False, False]).head(10)

    
    # Filter only the POIs with 'poiType' being 'Attraction'
    df_new = df_new[df_new['poiType'] == 'Attraction']

    print('TOP %s Attractions LIKE %s WITH SIMILAR Type, Tag, and Rating: ' % (str(len(df_new)), name))

    print(df_new)

    return {
        "content_based_attractions": df_new.drop(columns=['cosine similarity']).to_dict(orient='records'),
    }


# @app.route('/recommend_restaurant_content_based', methods=['GET'])
# def recommend_restaurants_content_based():
#     poi_name = request.args.get('poiName')
#     recommendations = recommend_restaurant_content_based(poi_name)
#     return jsonify(recommendations)

# def recommend_restaurant_content_based(name):
#     poi_data = pd.read_csv(poi_file_path)

#     # Set the index to 'poiName'
#     poi_data.set_index('poiName', inplace=True)

#     # Create a series of the POI names
#     poi_indices = pd.Series(poi_data.index)

#     poi_data['poiTag'] = poi_data['poiTag'].replace(-1, '')
#     poi_data['poiTag'].fillna('', inplace=True)

#     # Creating tf-idf matrix based on 'poiTag'
#     tfidf = TfidfVectorizer(analyzer='word', ngram_range=(1, 2), stop_words='english', min_df=1)
#     tfidf_matrix = tfidf.fit_transform(poi_data['poiTag'])

#     # Calculate cosine similarities based on 'poiTag'
#     cosine_similarities = linear_kernel(tfidf_matrix, tfidf_matrix)

#     # Find the index of the POI entered
#     idx = poi_indices[poi_indices == name].index[0]
    
#     # Find the POIs with similar cosine-sim value and order them from the biggest number
#     score_series = pd.Series(cosine_similarities[idx]).sort_values(ascending=False)
    
#     # Extract top 30 POI indexes with similar cosine-sim value
#     top30_indexes = list(score_series.iloc[0:31].index)
    
#     # Retrieve the name of the top 30 similar POIs based on their indexes
#     recommend_pois = [list(poi_data.index)[each] for each in top30_indexes]
    
#     # Create a list to store DataFrames
#     dfs = []

#     for each in recommend_pois:
#         if each != name:  # Exclude the entered POI
#             cosine_similarity = cosine_similarities[idx][list(poi_data.index).index(each)]
#             temp_df = poi_data[['poiID', 'poiType', 'poiTag', 'poiPrice', 'poiRating']][poi_data.index == each]
#             temp_df['cosine similarity'] = cosine_similarity
#             temp_df['poiName'] = each
#             dfs.append(temp_df)

#     # Concatenate the list of DataFrames
#     df_new = pd.concat(dfs, ignore_index=True)

#     # Drop the same named POIs and sort only the top 10 by the highest rating
#     df_new = df_new.drop_duplicates(subset=['poiName'], keep='first')
#     df_new = df_new.sort_values(by=['cosine similarity', 'poiRating'], ascending=[False, False]).head(8)
    
#     # Filter only the POIs with 'poiType' being 'Restaurant'
#     df_new = df_new[df_new['poiType'] == 'Restaurant']

#     print('TOP %s POIs LIKE %s WITH SIMILAR Type, Tag, Price, and Rating: ' % (str(len(df_new)), name))

#     print(df_new)

#     return {
#         "content_based_restaurants": df_new.drop(columns=['cosine similarity']).to_dict(orient='records'),
#     }

@app.route('/recommend_restaurant_content_based', methods=['GET'])
def recommend_restaurants_content_based():
    poi_name = request.args.get('poiName')
    recommendations = recommend_restaurant_content_based(poi_name)
    return jsonify(recommendations)

def recommend_restaurant_content_based(name):
    poi_data = pd.read_csv(poi_file_path)

    # Set the index to 'poiName'
    poi_data.set_index('poiName', inplace=True)

    # Create a series of the POI names
    poi_indices = pd.Series(poi_data.index)

    poi_data['poiTag'] = poi_data['poiTag'].replace(-1, '')
    poi_data['poiTag'].fillna('', inplace=True)

    # Combine 'poiType', 'poiTag', 'poiRating', and 'poiPrice' into a single string for each POI
    poi_data['combined_features'] = (
        poi_data['poiType'] + ' ' +
        poi_data['poiTag'] + ' ' +
        poi_data['poiRating'].astype(str) + ' ' +
        poi_data['poiPrice'].astype(str)
    )

    print("Combined Features:")
    print(poi_data['combined_features'])

    # Creating tf-idf matrix based on 'combined_features'
    tfidf = TfidfVectorizer(analyzer='word', ngram_range=(1, 2), stop_words='english', min_df=1)
    tfidf_matrix = tfidf.fit_transform(poi_data['combined_features'])

    print("\nTF-IDF Matrix:")
    print(tfidf_matrix)

    # Calculate cosine similarities based on 'combined_features'
    cosine_similarities = linear_kernel(tfidf_matrix, tfidf_matrix)

    # Find the index of the POI entered
    idx = poi_indices[poi_indices == name].index[0]

    # Find the POIs with similar cosine-sim value and order them from the biggest number
    score_series = pd.Series(cosine_similarities[idx]).sort_values(ascending=False)

    # Extract top 30 POI indexes with similar cosine-sim value
    top30_indexes = list(score_series.iloc[0:31].index)

    # Retrieve the name of the top 30 similar POIs based on their indexes
    recommend_pois = [list(poi_data.index)[each] for each in top30_indexes]

    # Create a list to store DataFrames
    dfs = []

    for each in recommend_pois:
        if each != name:  # Exclude the entered POI
            cosine_similarity = cosine_similarities[idx][list(poi_data.index).index(each)]
            temp_df = poi_data[['poiID', 'poiType', 'poiTag', 'poiPrice', 'poiRating']][poi_data.index == each]
            temp_df['cosine similarity'] = cosine_similarity
            temp_df['poiName'] = each
            dfs.append(temp_df)

    # Concatenate the list of DataFrames
    df_new = pd.concat(dfs, ignore_index=True)

    # Drop the same named POIs and sort only the top 10 by the highest rating
    df_new = df_new.drop_duplicates(subset=['poiName'], keep='first')
    df_new = df_new.sort_values(by=['cosine similarity', 'poiRating'], ascending=[False, False]).head(10)

    # Filter only the POIs with 'poiType' being 'Restaurant'
    df_new = df_new[df_new['poiType'] == 'Restaurant']

    print(f'TOP {len(df_new)} POIs LIKE {name} WITH SIMILAR Type, Tag, Price, and Rating:')
    
    print(df_new)

    return {
        "content_based_restaurants": df_new.drop(columns=['cosine similarity']).to_dict(orient='records'),
    }

@app.route('/get_top_rated_poi', methods=['GET'])
def recommend_top_rated_poi():
    results = get_top_rated_poi()
    return jsonify(results)

def get_top_rated_poi():
    df = pd.read_csv(poi_file_path)

    # Reset the index and rename the 'index' column to 'poiID'
    df = df.reset_index().rename(columns={'index': 'poiID'})


    # Convert 'poiRating' to float
    df['poiRating'] = pd.to_numeric(df['poiRating'], errors='coerce')
    # Convert 'poiNoOfReviews' to numeric
    df['poiNoOfReviews'] = pd.to_numeric(df['poiNoOfReviews'], errors='coerce')

    # Drop rows with missing values in 'poiRating' and 'poiNoOfReviews'
    df = df.dropna(subset=['poiRating', 'poiNoOfReviews'])

    # Calculate and display the mean rating without converting to numeric
    C = df['poiRating'].mean(skipna=True)
    print("Mean Rating:", C)

    # Calculate and display the quantile
    m = df['poiNoOfReviews'].quantile(0.5)
    print("Quantile (60%):", m)

    # Filter places based on the quantile
    q_place = df.copy().loc[df['poiNoOfReviews'] >= m]
    print("Filtered Places Shape:", q_place.shape)

    # Define the weighted rating function
    def weighted_rating(x, m=m, C=C):
        v = x['poiNoOfReviews']
        R = x['poiRating']
        # Calculation based on the formula
        return (v/(v+m) * R) + (m/(m+v) * C)

    # Define a new feature 'score' and calculate its value with `weighted_rating()`
    q_place['score'] = q_place.apply(weighted_rating, axis=1)

    # Sort places based on score
    q_place = q_place.sort_values('score', ascending=False)

    # Display the top 10 places
    print(q_place[['poiID', 'poiName', 'poiNoOfReviews', 'poiRating', 'score']].head(10))

    recommendations = q_place.drop(columns=['score']).to_dict(orient='records')
    return recommendations

@app.route('/get_top_rated_poi_in_location', methods=['GET'])
def top_rated_poi_in_location():
    # Get location parameters from the request
    latitude = request.args.get('latitude', type=float)
    longitude = request.args.get('longitude', type=float)

     # Calculate top-rated POIs
    top_rated_poi = get_top_rated_poi()

    # Check if latitude and longitude are provided
    if latitude is None or longitude is None:
        return jsonify({"error": "Latitude and longitude must be provided"}), 400

    # Filter recommendations within the specified location using Haversine distance
    radius_km = 90  # Set your desired radius
    nearby_points = []

    for poi in top_rated_poi:
        poi_latitude = poi.get('poiLatitude')
        poi_longitude = poi.get('poiLongitude')

        # Check if coordinates are not None
        if poi_latitude is not None and poi_longitude is not None:
            poi_coordinates = (poi_latitude, poi_longitude)
            distance = haversine((latitude, longitude), poi_coordinates, unit=Unit.KILOMETERS)
            
            if distance <= radius_km:
                nearby_points.append(poi)

    # Create a new DataFrame
    result = pd.DataFrame(nearby_points).head(12)
    print(f'Top Rated Poi in Location: {result}')

    return jsonify({"top_rated_poi_in_location": result.to_dict(orient='records')})


@app.route('/get_top_rated_hotel_in_location', methods=['GET'])
def top_rated_hotel_in_location():
    # Get location parameters from the request
    latitude = request.args.get('latitude', type=float)
    longitude = request.args.get('longitude', type=float)

    # Calculate top-rated POIs
    top_rated_poi = get_top_rated_poi()

    # Check if latitude and longitude are provided
    if latitude is None or longitude is None:
        return jsonify({"error": "Latitude and longitude must be provided"}), 400

    # Filter recommendations within the specified location using Haversine distance
    radius_km = 80  
    nearby_points = []

    for poi in top_rated_poi:
        poi_latitude = poi.get('poiLatitude')
        poi_longitude = poi.get('poiLongitude')

        # Check if coordinates are not None
        if poi_latitude is not None and poi_longitude is not None:
            poi_coordinates = (poi_latitude, poi_longitude)
            distance = haversine((latitude, longitude), poi_coordinates, unit=Unit.KILOMETERS)
            
            if distance <= radius_km and poi.get('poiType') == 'Hotel':
                nearby_points.append(poi)

    # Create a new DataFrame
    result = pd.DataFrame(nearby_points).head(16)
    print(f'Top Rated Poi in Location (Hotel only): {result}')

    return jsonify({"top_rated_hotel_in_location": result.to_dict(orient='records')})

@app.route('/get_restaurant_in_location', methods=['GET'])
def restaurant_in_location():
    # Get location parameters from the request
    latitude = request.args.get('latitude', type=float)
    longitude = request.args.get('longitude', type=float)

    # Read the DataFrame from poi_updated.csv
    poi_data = pd.read_csv(poi_file_path)

    # Check if latitude and longitude are provided
    if latitude is None or longitude is None:
        return jsonify({"error": "Latitude and longitude must be provided"}), 400

    # Filter recommendations within the specified location using Haversine distance
    radius_km = 50 
    nearby_points = []

    for index, poi in poi_data.iterrows():
        poi_latitude = poi['poiLatitude']
        poi_longitude = poi['poiLongitude']

        # Check if coordinates are not None
        if not pd.isna(poi_latitude) and not pd.isna(poi_longitude):
            poi_coordinates = (poi_latitude, poi_longitude)
            distance = haversine((latitude, longitude), poi_coordinates, unit=Unit.KILOMETERS)

            if distance <= radius_km and poi['poiType'] == 'Restaurant':
                nearby_points.append(poi)

    # Create a new DataFrame
    result = pd.DataFrame(nearby_points).head(16)
    print(f'Nearby Restaurant: {result}')

    return jsonify({"restaurant_in_location": result.to_dict(orient='records')})



############
#POI DETAILS
############

# Route to get CSV data
poi_file_path = '/home/geremytanyentsen/poi_updated.csv'

@app.route('/get_nearby_points_of_interest', methods=['GET'])
def get_nearby_points_of_interest():
    df = pd.read_csv(poi_file_path)

    # Get target poiID from HTTP request
    target_poi_id = request.args.get('query', default='', type=str)
    radius_km=5

    # Check if the target poiID is valid and exists in the DataFrame
    if target_poi_id and target_poi_id in df['poiID'].values:
        target_poi_row = df[df['poiID'] == target_poi_id].iloc[0]
        target_coordinates = (target_poi_row['poiLatitude'], target_poi_row['poiLongitude'])

        nearby_points = []

        # Calculate distances and filter points of interest within the specified radius
        for _, row in df.iterrows():
            if (
                row['poiID'] != target_poi_id
                and row['poiLatitude'] is not None
                and row['poiLongitude'] is not None
            ):
                other_coordinates = (row['poiLatitude'], row['poiLongitude'])
                distance = haversine(target_coordinates, other_coordinates, unit=Unit.KILOMETERS)

                if distance <= radius_km:
                    nearby_points.append({
                        "poiID": row['poiID'],
                        "poiType": row['poiType'],
                        "poiName": row['poiName'],
                        "poiAddress": row.get('poiAddress', ''),
                        "poiLocation": distance,
                        "poiUrl": row.get('poiUrl', ''),
                        "poiPriceRange": row.get('poiPriceRange', ''),
                        "poiPrice": row.get('poiPrice', ''),
                        "poiPhone": row.get('poiPhone', ''),
                        "poiTag": row.get('poiTag', ''),
                        "poiOperatingHours": row.get('poiOperatingHours', ''),
                        "poiRating": row.get('poiRating', ''),
                        "poiNoOfReviews": row.get('poiNoOfReviews', ''),
                        "poiDescription": row.get('poiDescription', ''),
                        "poiLatitude": row['poiLatitude'],
                        "poiLongitude": row['poiLongitude'],
                        
                    })

        # Sort points of interest by poiLocation (distance)
        nearby_points.sort(key=lambda x: x["poiLocation"])


        # Create a new DataFrame with the top 50 closest points
        top_50_df = pd.DataFrame(nearby_points[:50])
        print(f'Top 50 Results: {top_50_df}')

        # Return the new DataFrame and the entire DataFrame as JSON
        return jsonify({
            "top_50_nearby_points": top_50_df.to_dict(orient='records'),
        })
    else:
        return jsonify({"error": "Invalid poiID or poiID not found"}), 400
    
@app.route('/get_all_poi_df', methods=['GET'])
def get_all_poi_df():
    try:
        # Read data from the CSV file into a pandas DataFrame
        df = pd.read_csv(poi_file_path)

        # Drop rows with null values
        df = df.dropna()

        # Print the top 20 results for debugging
        results = df.to_dict(orient='records')
        
        # Return the data as JSON
        return jsonify(results)

    except Exception as e:
        # Print the error details for debugging
        print(f'Error in get_poi_df: {e}')
        return jsonify({'error': str(e)}), 500

    
@app.route('/get_poi_df', methods=['GET'])
def get_poi_df():
    try:
        # Read data from the CSV file into a pandas DataFrame
        df = pd.read_csv(poi_file_path)

         # Print the top 20 results for debugging
        top_20_results = df.head(20).to_dict(orient='records')
        print(f'Top 20 Results: {top_20_results}')

        # Return the data as JSON
        return jsonify(top_20_results)

    except Exception as e:
        # Print the error details for debugging
        print(f'Error in get_poi_df: {e}')
        return jsonify({'error': str(e)}), 500

@app.route('/search_poi', methods=['GET'])
def search_poi():
    try:
        # Read data from the CSV file into a pandas DataFrame
        df = pd.read_csv(poi_file_path)

        # Get the search query from the request parameters
        query = request.args.get('query', default='', type=str)

        # Filter places based on the search query
        filtered_places = df[df.apply(lambda row: row.astype(str).str.contains(query, case=False).any(), axis=1)]

        # Convert the filtered data to a list of dictionaries (JSON-friendly format)
        data_for_search = filtered_places.head(20).to_dict(orient='records')

        # Return the filtered data as JSON
        return jsonify(data_for_search)

    except Exception as e:
        # Print the error details for debugging
        print(f'Error in search_poi: {e}')
        return jsonify({'error': str(e)}), 500

@app.route('/get_poi_based_on_id', methods=['GET'])
def get_poi_based_on_id():
    try:
        # Read data from the CSV file into a pandas DataFrame
        df = pd.read_csv(poi_file_path)

        # Get the poiID from the request parameters
        poi_id = request.args.get('query', default='', type=str)

        # Filter places based on the poiID
        filtered_place = df[df['poiID'] == poi_id]

        # Convert the filtered data to a dictionary (JSON-friendly format)
        data_for_search = filtered_place.to_dict(orient='records')

        # Return the filtered data as JSON
        return jsonify(data_for_search)
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"error": "Internal Server Error"}), 500

@app.route('/save-poi-details', methods=['POST'])
def save_poi_details():

    # Read data from the CSV file into a pandas DataFrame
    df = pd.read_csv(poi_file_path)

    poi_details = request.form

    # Convert POI details to a DataFrame
    new_data = pd.DataFrame([poi_details], columns=df.columns)

    # Append new data to the existing DataFrame
    updated_df = pd.concat([df, new_data], ignore_index=True)

    # Write the updated DataFrame to a CSV file
    updated_df.to_csv('poi_updated.csv', index=False)

    return 'POI details saved successfully', 200

@app.route('/edit-poi-details', methods=['POST'])
def edit_poi_details():
    try:
        # Read data from the CSV file into a pandas DataFrame
        df = pd.read_csv(poi_file_path)

        # Extract POI details from the POST request
        poi_details = request.form

        # Find the index of the POI with the specified ID
        poi_id = poi_details.get('poiID')
        poi_index = df[df['poiID'] == poi_id].index.item()

        # Update details of the identified POI
        df.loc[poi_index] = poi_details

        # Write the updated DataFrame to a CSV file
        df.to_csv(poi_file_path, index=False)

        return 'POI details saved successfully', 200
    except Exception as e:
        print(f'Error saving POI details: {e}')
        return 'Internal server error', 500

@app.route('/delete-poi', methods=['POST'])
def delete_poi():
    try:
        # Read data from the CSV file into a pandas DataFrame
        df = pd.read_csv(poi_file_path)

        # Extract POI ID from the POST request
        poi_id = int(request.form.get('poiID'))

        # Find the index of the POI with the specified ID
        poi_index = df[df['poiID'] == poi_id].index.item()

        # Drop the row corresponding to the identified POI
        df = df.drop(index=poi_index)

        # Write the updated DataFrame to a CSV file
        df.to_csv(poi_file_path, index=False)

        return 'POI deleted successfully', 200
    except Exception as e:
        print(f'Error deleting POI: {e}')
        return 'Internal server error', 500
    

@app.route('/get-last-poi-id', methods=['GET'])
def get_last_poi_id():
    # Read data from the CSV file into a pandas DataFrame
    df = pd.read_csv(poi_file_path)

    try:
        # Check if there are any existing rows in the DataFrame
        if not df.empty:
            # Retrieve the last poiID
            last_poi_id = df['poiID'].iloc[-1]
            return jsonify({'lastPoiID': last_poi_id})
        else:
            return jsonify({'lastPoiID': ''})  # Return an empty string if there are no rows

    except Exception as e:
        return jsonify({'error': str(e)})
    

# Define the route for the demographic recommendations
@app.route('/get_demographic_recommendations', methods=['POST'])
def recommend_demographic():
    try:
        # Retrieve demographic data from the JSON body of the HTTP request
        data = request.get_json()
        
        country = data['country']
        age = data['age']
        gender = data['gender']

        # Create a dictionary with demographic data
        demographic_data = {'country': country, 'age': age, 'gender': gender}

        # Call the recommend_demographic function with the demographic data
        recommendations = recommend_demographic_internal(demographic_data)

        # Return the recommendations as JSON
        return jsonify(recommendations)

    except Exception as e:
        return jsonify({'error': str(e)})

def recommend_demographic_internal(demographic_data):
    try:
        # Load user data
        user_data = pd.read_csv('/home/geremytanyentsen/user_data.csv', encoding='latin-1')

        # Load rating data
        rating_data = pd.read_csv('/home/geremytanyentsen/activity_data.csv', encoding='latin-1')

        # Merge user data and rating data
        merged_data = pd.merge(rating_data, user_data, on='userID')

        # Convert non-numeric demographic features to strings
        user_data['country'] = user_data['country'].astype(str)
        user_data['age'] = user_data['age'].astype(str)
        user_data['gender'] = user_data['gender'].astype(str)

        # Get the demographic details for the current user
        current_user_demographics = pd.DataFrame([demographic_data])

        # Create a one-hot encoding for user demographic data
        encoder = OneHotEncoder(sparse=False, drop='first')
        user_data_encoded = encoder.fit_transform(user_data[['country','age', 'gender']])

        # Encode the current user's demographics
        current_user_demographics_encoded = encoder.transform(current_user_demographics)

        # Calculate cosine similarity between users based on demographic details
        similarity_matrix = cosine_similarity(user_data_encoded, current_user_demographics_encoded)

        # Get similar users based on demographic details
        similar_users = list(enumerate(similarity_matrix[:, 0]))
        similar_users = sorted(similar_users, key=lambda x: x[1], reverse=True)

        # Collect POI ratings for all similar users
        poi_ratings = []
        seen_users = set()  # To keep track of seen users
        for similar_user_index, similarity_score in similar_users[1:6]:
            similar_user_data = user_data.iloc[similar_user_index]
            similar_user_id = similar_user_data['userID']

            # Check if the user has already been displayed
            if similar_user_id not in seen_users:
                seen_users.add(similar_user_id)

                # Collect POI ratings
                user_ratings = merged_data[merged_data['userID'] == similar_user_id].sort_values(by='activityRating', ascending=False)
                poi_ratings.extend(user_ratings[['poiID', 'activityRating']].values.tolist())

        # Sort and get the top 10 POIs
        top_pois = sorted(poi_ratings, key=lambda x: x[1], reverse=True)[:10]

        # Extract the top 10 POI IDs
        top_poi_ids = [poi_id for poi_id, _ in top_pois]

        # Create a new DataFrame from poi_updated.csv
        poidf = pd.read_csv('/home/geremytanyentsen/poi_updated.csv')  # Replace 'path_to_poi_updated.csv' with the actual path

        # Filter places based on the top 10 POI IDs
        top_pois_df = poidf[poidf['poiID'].isin(top_poi_ids)]

        # Merge with top_pois_df and sort by ratings
        result_df = pd.merge(top_pois_df, pd.DataFrame(top_pois, columns=['poiID', 'rating']), on='poiID')
        result_df = result_df.sort_values(by='rating', ascending=False)

        print(result_df.drop(columns=['rating']))

        # Return the overall top 10 POIs
        return {
            "top_10_demo": result_df.drop(columns=['rating']).to_dict(orient='records'),
        }

    except Exception as e:
        return {'error': str(e)}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
