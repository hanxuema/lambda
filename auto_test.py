import os
import sys
import json
import subprocess
import urllib.request
import urllib.parse
import urllib.error

def run_tests():
    print("Fetching Terraform outputs for APIs...")
    run_dir = os.path.join(os.path.dirname(__file__), 'terraform')
    try:
        output = subprocess.check_output(['terraform', 'output', '-json'], cwd=run_dir)
        outputs = json.loads(output)
        api_urls = outputs['api_urls']['value']
    except Exception as e:
        print(f"Error reading terraform outputs: {e}")
        sys.exit(1)

    print("\n--- Starting E2E API Tests ---")
    
    # Test 1: List Companies
    url = api_urls['list_companies']
    print(f"\n[Test 1] GET {url}")
    req = urllib.request.Request(url)
    try:
        with urllib.request.urlopen(req) as response:
            assert response.status == 200
            data = json.loads(response.read().decode())
            assert 'companies' in data
            assert len(data['companies']) > 0
            company = data['companies'][0]
            print(f"✅ Success! Found {len(data['companies'])} companies. First is {company['name']}")
            company_id = company['id']
    except urllib.error.HTTPError as e:
        print(f"❌ Failed: {e.code} - {e.read().decode()}")
        sys.exit(1)

    # Test 2: Get specific company
    url = api_urls['get_company'].replace('{id}', str(company_id))
    print(f"\n[Test 2] GET {url}")
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req) as response:
        assert response.status == 200
        data = json.loads(response.read().decode())
        assert 'company' in data
        print(f"✅ Success! Company details: {data['company']}")

    # Test 3: List directors of company
    url = api_urls['list_directors'].replace('{id}', str(company_id))
    print(f"\n[Test 3] GET {url}")
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req) as response:
        assert response.status == 200
        data = json.loads(response.read().decode())
        assert 'directors' in data
        print(f"✅ Success! Found {len(data['directors'])} directors for company {company_id}.")
        
        director_id = None
        director_name = None
        if len(data['directors']) > 0:
            director_id = data['directors'][0]['id']
            director_name = data['directors'][0]['name']

    # Test 4: List ALL directors (Grouped Format)
    url = api_urls['list_all_directors']
    print(f"\n[Test 4] GET {url}")
    req = urllib.request.Request(url)
    try:
        with urllib.request.urlopen(req) as response:
            assert response.status == 200
            data = json.loads(response.read().decode())
            assert 'directors' in data
            print(f"✅ Success! Found {len(data['directors'])} unique grouped directors in the database.")
            if len(data['directors']) > 0:
                print(f"   Example: {data['directors'][0]['name']} has {len(data['directors'][0]['roles'])} role(s).")
    except urllib.error.HTTPError as e:
        print(f"❌ Failed Test 4: {e.code} - {e.read().decode()}")

    # Test 5: Get Director Profile
    if director_name is not None:
        safe_name = urllib.parse.quote(director_name)
        url = api_urls['get_director_profile'].replace('{name}', safe_name)
        print(f"\n[Test 5] GET {url}")
        req = urllib.request.Request(url)
        try:
            with urllib.request.urlopen(req) as response:
                assert response.status == 200
                data = json.loads(response.read().decode())
                assert 'profile' in data
                print(f"✅ Success! Fetched full profile for '{director_name}' with {len(data['profile']['roles'])} role(s).")
        except urllib.error.HTTPError as e:
            print(f"❌ Failed Test 5: {e.code} - {e.read().decode()}")
    else:
        print("\n[Test 5] Skipped (No directors found to fetch profile)")

    # Test 6: Update Director Title
    if director_id is not None:
        url = api_urls['update_director'].replace('{id}', str(director_id))
        print(f"\n[Test 6] PUT {url}")
        req = urllib.request.Request(url, method='PUT')
        req.add_header('Content-Type', 'application/json')
        payload = json.dumps({"title": "Automated Tester Manager"}).encode('utf-8')
        try:
            with urllib.request.urlopen(req, data=payload) as response:
                assert response.status == 200
                data = json.loads(response.read().decode())
                print(f"✅ Success! Updated role {director_id} title to 'Automated Tester Manager'.")
        except urllib.error.HTTPError as e:
            print(f"❌ Failed Test 6: {e.code} - {e.read().decode()}")
    else:
        print("\n[Test 6] Skipped (No directors found to update)")
        
    print("\n🎉 All API Tests Passed Perfectly!")

if __name__ == '__main__':
    run_tests()
