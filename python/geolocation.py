import csv
from geopy.geocoders import Nominatim
from haversine import haversine, Unit

def read_csv(file_path):
    with open(file_path, 'r', encoding='utf-8-sig') as file:
        reader = csv.DictReader(file)
        data = [row for row in reader]
    return data



def get_nearby_points_of_interest(csv_data, target_poi_id, radius_km=5):
    nearby_points = []

    for poi in csv_data:
        # Check if 'poiID' is present in the dictionary
        if 'poiID' in poi and poi['poiID'] == target_poi_id and poi['poiID'].startswith('P') and poi['poiID'][1:].isdigit():
            target_coordinates = (
                float(poi['poiLatitude']), 
                float(poi['poiLongitude'])
            ) if poi.get('poiLatitude') and poi.get('poiLongitude') else None

            # Calculate distances and filter points of interest within the specified radius
            for other_poi in csv_data:
                # Check if 'poiLatitude' and 'poiLongitude' are present in the dictionary
                if (
                    'poiID' in other_poi 
                    and other_poi['poiID'].startswith('P') 
                    and other_poi['poiID'][1:].isdigit()
                    and 'poiLatitude' in other_poi 
                    and 'poiLongitude' in other_poi
                    and other_poi['poiLatitude'] and other_poi['poiLongitude']
                ):
                    other_coordinates = (
                        float(other_poi['poiLatitude']), 
                        float(other_poi['poiLongitude'])
                    )
                    distance = haversine(target_coordinates, other_coordinates, unit=Unit.KILOMETERS)
                    if distance <= radius_km and other_poi['poiID'] != target_poi_id:
                        nearby_points.append({
                            "poiID": other_poi['poiID'], 
                            "poiName": other_poi['poiName'], 
                            "poiAddress": other_poi.get('poiAddress', ''),  # Add poiAddress with a default value of ''
                            "distance": distance
                        })

    # Sort points of interest by distance
    nearby_points.sort(key=lambda x: x["distance"])

    return nearby_points[:20]  # Select the top 20 results

# Example usage
csv_file_path = 'C:\\Users\\gerem\\OneDrive\\Desktop\\MyTravelMate\\data\\poi_updated.csv'
poi_id_input = input("Enter the poiID: ")
poi_data = read_csv(csv_file_path)

recommended_points = get_nearby_points_of_interest(poi_data, poi_id_input, radius_km=5)

print(f"Top 20 Points of Interest near poiID {poi_id_input}:")
for poi in recommended_points:
    print(f"{poi['poiID']} - {poi['poiName']} - Address: {poi['poiAddress']} - Distance: {poi['distance']:.2f} km")
