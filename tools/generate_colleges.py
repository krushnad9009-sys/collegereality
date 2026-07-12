import json
import random

random.seed(42)

states_cities = {
    "Maharashtra": ["Mumbai", "Pune", "Nagpur", "Nashik", "Aurangabad"],
    "Karnataka": ["Bangalore", "Mysore", "Mangalore", "Hubli", "Belgaum"],
    "Tamil Nadu": ["Chennai", "Coimbatore", "Madurai", "Trichy", "Salem"],
    "Delhi": ["New Delhi", "Dwarka", "Rohini"],
    "Uttar Pradesh": ["Lucknow", "Kanpur", "Noida", "Varanasi", "Agra"],
    "Gujarat": ["Ahmedabad", "Surat", "Vadodara", "Rajkot"],
    "Rajasthan": ["Jaipur", "Udaipur", "Jodhpur", "Kota"],
    "West Bengal": ["Kolkata", "Howrah", "Durgapur", "Siliguri"],
    "Telangana": ["Hyderabad", "Warangal", "Karimnagar"],
    "Andhra Pradesh": ["Visakhapatnam", "Vijayawada", "Guntur", "Tirupati"],
    "Kerala": ["Kochi", "Thiruvananthapuram", "Kozhikode", "Thrissur"],
    "Punjab": ["Chandigarh", "Ludhiana", "Amritsar", "Jalandhar"],
    "Haryana": ["Gurgaon", "Faridabad", "Panipat", "Rohtak"],
    "Madhya Pradesh": ["Bhopal", "Indore", "Gwalior", "Jabalpur"],
    "Bihar": ["Patna", "Gaya", "Muzaffarpur"],
    "Odisha": ["Bhubaneswar", "Cuttack", "Rourkela"],
    "Assam": ["Guwahati", "Silchar", "Dibrugarh"],
    "Jharkhand": ["Ranchi", "Jamshedpur", "Dhanbad"],
    "Chhattisgarh": ["Raipur", "Bhilai", "Bilaspur"],
    "Himachal Pradesh": ["Shimla", "Mandi", "Solan"],
}

prefixes = [
    "National", "Global", "Premier", "Central", "Modern", "Royal",
    "Elite", "Progressive", "United", "Heritage",
]
suffixes = [
    "Institute of Technology", "College of Engineering", "University",
    "Institute of Management", "Polytechnic", "Academy of Science",
    "School of Business", "College of Arts", "Institute of Medical Sciences",
    "College of Pharmacy",
]
types = ["government", "private", "deemed"]
courses_pool = [
    ["B.Tech", "M.Tech"], ["BBA", "MBA"], ["B.Sc", "M.Sc"],
    ["B.Com", "M.Com"], ["MBBS", "MD"], ["B.Pharm", "M.Pharm"],
    ["BCA", "MCA"], ["BA", "MA"],
]
recruiters = ["TCS", "Infosys", "Wipro", "Google", "Microsoft", "Amazon", "Deloitte", "Accenture"]

colleges = []
index = 0

for state, cities in states_cities.items():
    for city in cities:
        if index >= 100:
            break
        name = f"{random.choice(prefixes)} {city} {random.choice(suffixes)}"
        slug = name.lower().replace(" ", "-").replace(".", "")[:50] + f"-{index}"
        rating = round(random.uniform(3.2, 4.9), 1)
        colleges.append({
            "id": f"college_{index + 1:03d}",
            "name": name,
            "slug": slug,
            "city": city,
            "state": state,
            "address": f"{random.randint(1, 999)} University Road, {city}",
            "type": random.choice(types),
            "courses": random.choice(courses_pool),
            "website": f"https://www.college{index}.edu.in",
            "coverPhotoUrl": None,
            "photoUrls": [],
            "fees": {
                "tuitionMin": random.randint(50000, 200000),
                "tuitionMax": random.randint(200000, 800000),
                "hostelAnnual": random.randint(30000, 150000),
            },
            "scholarships": [{
                "name": "Merit Scholarship",
                "eligibility": "Above 90% in 12th",
                "amount": "Up to 50% fee waiver",
            }],
            "placements": {
                "highestPackageLpa": round(random.uniform(8, 45), 1),
                "averagePackageLpa": round(random.uniform(3, 18), 1),
                "placementPercentage": random.randint(60, 98),
                "topRecruiters": random.sample(recruiters, 4),
            },
            "aggregatedRatings": {
                "overall": rating,
                "faculty": round(rating + random.uniform(-0.3, 0.3), 1),
                "infrastructure": round(rating + random.uniform(-0.4, 0.2), 1),
                "placements": round(rating + random.uniform(-0.2, 0.4), 1),
                "campusLife": round(rating + random.uniform(-0.5, 0.3), 1),
            },
            "reviewCount": random.randint(50, 2500),
            "searchKeywords": list({name.lower(), city.lower(), state.lower(), *name.lower().split()}),
            "isActive": True,
        })
        index += 1
    if index >= 100:
        break

while index < 100:
    state = random.choice(list(states_cities.keys()))
    city = random.choice(states_cities[state])
    name = f"{random.choice(prefixes)} {city} {random.choice(suffixes)}"
    slug = name.lower().replace(" ", "-")[:50] + f"-{index}"
    rating = round(random.uniform(3.2, 4.9), 1)
    colleges.append({
        "id": f"college_{index + 1:03d}",
        "name": name,
        "slug": slug,
        "city": city,
        "state": state,
        "address": f"{random.randint(1, 999)} Campus Road, {city}",
        "type": random.choice(types),
        "courses": random.choice(courses_pool),
        "website": f"https://www.college{index}.edu.in",
        "coverPhotoUrl": None,
        "photoUrls": [],
        "fees": {"tuitionMin": 80000, "tuitionMax": 400000, "hostelAnnual": 60000},
        "scholarships": [{"name": "Need-based Aid", "eligibility": "Family income below 5 LPA", "amount": "25% waiver"}],
        "placements": {"highestPackageLpa": 20.0, "averagePackageLpa": 8.5, "placementPercentage": 75, "topRecruiters": recruiters[:3]},
        "aggregatedRatings": {"overall": rating, "faculty": rating, "infrastructure": rating, "placements": rating, "campusLife": rating},
        "reviewCount": 200,
        "searchKeywords": [name.lower(), city.lower(), state.lower()],
        "isActive": True,
    })
    index += 1

import os
os.makedirs("assets/data", exist_ok=True)
with open("assets/data/colleges_seed.json", "w", encoding="utf-8") as f:
    json.dump(colleges, f, indent=2)

print(f"Generated {len(colleges)} colleges")
