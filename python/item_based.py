import pandas as pd
import numpy as np



from surprise import Reader, Dataset, SVD
from surprise.model_selection import train_test_split

# Load the dataset
reader = Reader()
ratings = pd.read_csv('../input/the-movies-dataset/ratings_small.csv')
data = Dataset.load_from_df(ratings[['userId', 'poiID', 'poiRating']], reader)

# Split the data into train and test sets
trainset, testset = train_test_split(data, test_size=0.25)

# Create and train the SVD model
svd = SVD()
svd.fit(trainset)

# Get similar users for a target user
target_user_id = 1
similar_users = svd.get_neighbors(target_user_id, k=10)  # Get 10 similar users

# Get items that similar users have liked but the target user hasn't interacted with
target_user_items = set(ratings[ratings['userId'] == target_user_id]['movieId'])
recommendations = []

for user_id in similar_users:
    user_items = set(ratings[ratings['userId'] == user_id]['movieId'])
    new_items = user_items - target_user_items
    recommendations.extend(new_items)

# Filter out items that the target user has already interacted with
recommendations = [item for item in recommendations if item not in target_user_items]

# Display the recommendations
print(recommendations)
