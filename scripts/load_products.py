import http.client
import json
import sys
import time
from urllib.parse import urlparse


class ProductLoader:
    def __init__(self, base_url, timeout=30):
        """
        Initialize the product loader

        Args:
            base_url: Full URL like 'http://localhost:4000/api/load'
            timeout: Request timeout in seconds
        """
        parsed = urlparse(base_url)
        self.host = parsed.netloc
        self.path = parsed.path
        self.scheme = parsed.scheme
        self.timeout = timeout

        print(f"🔗 Target: {self.scheme}://{self.host}{self.path}")

    def load_products(self, json_file, batch_size=100):
        """
        Load products from JSON file to the API

        Args:
            json_file: Path to JSON file with products
            batch_size: Number of products to load before showing progress
        """
        # Read JSON file
        print(f"📖 Reading products from {json_file}...")
        with open(json_file, "r", encoding="utf-8") as f:
            products = json.load(f)

        total = len(products)
        print(f"📦 Found {total} products to load")
        print()

        # Statistics
        success_count = 0
        error_count = 0
        errors = []

        start_time = time.time()

        # Load each product
        for index, product in enumerate(products, 1):
            try:
                response = self._send_request(product)

                if response["status"] == 200:
                    success_count += 1
                else:
                    error_count += 1
                    errors.append(
                        {
                            "index": index,
                            "sku": product.get("sku", "unknown"),
                            "status": response["status"],
                            "error": response.get("body", "Unknown error"),
                        }
                    )

                # Show progress
                if index % batch_size == 0 or index == total:
                    elapsed = time.time() - start_time
                    rate = index / elapsed if elapsed > 0 else 0
                    progress = (index / total) * 100

                    print(
                        f"\r📊 Progress: {progress:.1f}% ({index}/{total}) | "
                        f"✅ {success_count} | ❌ {error_count} | "
                        f"⚡ {rate:.1f} req/s",
                        end="",
                        flush=True,
                    )

            except Exception as e:
                error_count += 1
                errors.append(
                    {
                        "index": index,
                        "sku": product.get("sku", "unknown"),
                        "error": str(e),
                    }
                )

        print()  # New line after progress
        print()

        # Summary
        elapsed = time.time() - start_time
        print("=" * 60)
        print("📈 SUMMARY")
        print("=" * 60)
        print(f"✅ Successful: {success_count}")
        print(f"❌ Failed: {error_count}")
        print(f"⏱️  Total time: {elapsed:.2f}s")
        print(f"⚡ Average rate: {total / elapsed:.1f} requests/second")
        print()

        # Show errors if any
        if errors:
            print("❌ ERRORS:")
            print("-" * 60)
            for error in errors[:10]:  # Show first 10 errors
                print(
                    f"  [{error['index']}] {error['sku']}: {error.get('error', error.get('status'))}"
                )

            if len(errors) > 10:
                print(f"  ... and {len(errors) - 10} more errors")
            print()

        return success_count, error_count, errors

    def _send_request(self, product):
        """Send HTTP PUT request to load a product"""
        try:
            # Create connection
            if self.scheme == "https":
                conn = http.client.HTTPSConnection(self.host, timeout=self.timeout)
            else:
                conn = http.client.HTTPConnection(self.host, timeout=self.timeout)

            # Prepare JSON body
            body = json.dumps(product)

            # Headers
            headers = {
                "Content-Type": "application/json",
                "Content-Length": str(len(body)),
            }

            # Send request
            conn.request("PUT", self.path, body, headers)

            # Get response
            response = conn.getresponse()
            status = response.status
            response_body = response.read().decode("utf-8")

            conn.close()

            # Parse response
            try:
                parsed_body = json.loads(response_body)
            except Exception:
                parsed_body = response_body

            return {"status": status, "body": parsed_body}

        except Exception as e:
            return {"status": 0, "body": str(e)}


def main():
    # Configuration
    API_URL = "http://localhost:4000/api/load"
    JSON_FILE = "products.json"
    BATCH_SIZE = 100

    # Parse command line arguments
    if len(sys.argv) > 1:
        JSON_FILE = sys.argv[1]

    if len(sys.argv) > 2:
        API_URL = sys.argv[2]

    print("=" * 60)
    print("🚀 PRODUCT LOADER")
    print("=" * 60)
    print()

    # Create loader
    loader = ProductLoader(API_URL)

    # Load products
    try:
        success, errors, error_list = loader.load_products(JSON_FILE, BATCH_SIZE)

        # Exit code based on results
        if errors == 0:
            print("✅ All products loaded successfully!")
            sys.exit(0)
        elif success > 0:
            print(f"⚠️  Loaded with {errors} errors")
            sys.exit(1)
        else:
            print("❌ Failed to load any products")
            sys.exit(2)

    except FileNotFoundError:
        print(f"❌ Error: File '{JSON_FILE}' not found")
        sys.exit(3)

    except KeyboardInterrupt:
        print()
        print("⚠️  Interrupted by user")
        sys.exit(130)

    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        import traceback

        traceback.print_exc()
        sys.exit(4)


if __name__ == "__main__":
    main()
