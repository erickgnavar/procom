import json
import random

categories = [
    "Laptop",
    "Mouse",
    "Keyboard",
    "Monitor",
    "Headphone",
    "Speaker",
    "Tablet",
    "Phone",
    "Camera",
    "Smartwatch",
    "Charger",
    "Cable",
    "Router",
    "Webcam",
    "Microphone",
    "Printer",
    "Scanner",
    "Drive",
    "RAM",
    "SSD",
    "GPU",
    "CPU",
    "Motherboard",
    "Case",
    "Fan",
    "Chair",
    "Desk",
    "Lamp",
    "Bag",
    "Stand",
    "Hub",
]

brands = [
    "Apple",
    "Samsung",
    "Dell",
    "HP",
    "Lenovo",
    "Asus",
    "Acer",
    "Logitech",
    "Razer",
    "Corsair",
    "Sony",
    "Bose",
    "JBL",
    "Microsoft",
    "Google",
    "Amazon",
    "Xiaomi",
    "Huawei",
    "Canon",
    "Nikon",
    "LG",
    "ViewSonic",
    "BenQ",
    "Anker",
]

adjectives = [
    "Pro",
    "Ultra",
    "Premium",
    "Elite",
    "Advanced",
    "Professional",
    "Gaming",
    "Portable",
    "Wireless",
    "Smart",
    "Compact",
    "Deluxe",
    "Standard",
    "Basic",
    "Essential",
    "Supreme",
    "Master",
    "Extreme",
]


def generate_product(index):
    category = random.choice(categories)
    brand = random.choice(brands)
    adjective = random.choice(adjectives)

    sku = f"{category.upper()}-{index:04d}"
    name = f"{brand} {category} {adjective}"

    descriptions = [
        f"High-quality {category.lower()} with excellent performance and durability",
        f"Perfect {category.lower()} for professionals and enthusiasts",
        f"State-of-the-art {category.lower()} with cutting-edge technology",
        f"Reliable {category.lower()} designed for everyday use",
        f"Premium {category.lower()} with advanced features and functionality",
    ]

    description = random.choice(descriptions)

    # Price between $10 and $5000 (in cents)
    price = random.randint(1000, 500000)

    # Rating between 1 and 5
    rating = random.randint(1, 5)

    # Image URL
    image_url = f"https://example.com/images/{category.lower()}-{index:04d}.jpg"

    return {
        "sku": sku,
        "name": name,
        "description": description,
        "image_url": image_url,
        "price": price,
        "rating": rating,
    }


def main():
    products = [generate_product(i) for i in range(1, 1001)]

    with open("products.json", "w", encoding="utf-8") as f:
        json.dump(products, f, indent=2, ensure_ascii=False)

    print(f"Generated {len(products)} products in products.json")


if __name__ == "__main__":
    main()
