import sys
import boto3
import json
import subprocess
import os
import random
import time

if len(sys.argv) == 3:
    print("Using provided ARNs from Terraform local-exec...")
    print("Waiting 15 seconds for Data API to fully warm up after instance creation...")
    time.sleep(15)
    cluster_arn = sys.argv[1]
    secret_arn = sys.argv[2]
else:
    print("Fetching Terraform outputs...")
    tf_dir = os.path.join(os.path.dirname(__file__), '../terraform')
    try:
        output = subprocess.check_output(['terraform', 'output', '-json'], cwd=tf_dir)
        outputs = json.loads(output)
        
        cluster_arn_output = subprocess.check_output(
            ['terraform', 'state', 'show', 'aws_rds_cluster.demo_cluster'], cwd=tf_dir
        ).decode('utf-8')
        cluster_arn = [line.split('=')[1].strip().strip('"') for line in cluster_arn_output.split('\n') if line.strip().startswith('arn')][0]

        secret_arn_output = subprocess.check_output(
            ['terraform', 'state', 'show', 'aws_secretsmanager_secret.db_secret'], cwd=tf_dir
        ).decode('utf-8')
        secret_arn = [line.split('=')[1].strip().strip('"') for line in secret_arn_output.split('\n') if line.strip().startswith('arn')][0]
    except Exception as e:
        print("Error fetching terraform state. Did you run 'terraform apply'?")
        exit(1)

db_name = "demodb"
client = boto3.client('rds-data', region_name='ap-southeast-2')

def execute(sql):
    res = client.execute_statement(
        secretArn=secret_arn,
        resourceArn=cluster_arn,
        database=db_name,
        sql=sql
    )
    return res

# --- Fake Data Generation Pool ---
industries = ["Technology", "E-commerce", "Finance", "Healthcare", "Energy", "Manufacturing", "Retail", "Media", "AI Research", "Logistics"]
prefixes = ["Alpha", "Beta", "Global", "Apex", "Nova", "Quantum", "Nexus", "Stellar", "Omega", "Prime", "Vertex", "Zeith", "Aura", "Crypto", "Eco", "Pioneer", "Summit", "Vanguard", "Titan", "Dynamic"]
suffixes = ["Tech", "Solutions", "Systems", "Holdings", "Group", "Corp", "Ventures", "Labs", "Partners", "Networks", "Inc", "LLC", "Global", "Enterprises"]
first_names = ["James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda", "William", "Elizabeth", "David", "Barbara", "Richard", "Susan", "Joseph", "Jessica", "Thomas", "Sarah", "Charles", "Karen", "Christopher", "Lisa", "Daniel", "Nancy", "Matthew", "Betty", "Anthony", "Margaret"]
last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson", "White", "Harris"]
titles = ["CEO", "CFO", "CTO", "COO", "Managing Director", "Executive Director", "Non-Executive Director", "Chairman", "Board Member", "President"]

random.seed(42) # Use fixed seed to ensure consistent data generation

# 1. Generate 50 unique companies
companies = []
company_names_set = set()
while len(companies) < 50:
    name = f"{random.choice(prefixes)} {random.choice(suffixes)}"
    if name not in company_names_set:
        company_names_set.add(name)
        companies.append((name, random.choice(industries)))

# 2. Generate 70 unique directors
unique_directors = []
director_names_set = set()
while len(unique_directors) < 70:
    name = f"{random.choice(first_names)} {random.choice(last_names)}"
    if name not in director_names_set:
        director_names_set.add(name)
        unique_directors.append(name)

# 3. Split directors: 30% (~21) shared across multiple companies, 70% dedicated to one company
shared_directors = unique_directors[:21]
dedicated_directors = unique_directors[21:]

company_director_mappings = []
dedicated_idx = 0

# Assign 1 to 3 directors per company
for c_idx in range(50):
    num_directors = random.randint(1, 3)
    
    for _ in range(num_directors):
        # ~30% chance to pull from the shared pool, or if we run out of dedicated directors
        use_shared = random.random() < 0.35 
        
        if use_shared or dedicated_idx >= len(dedicated_directors):
            director_name = random.choice(shared_directors)
        else:
            director_name = dedicated_directors[dedicated_idx]
            dedicated_idx += 1
            
        company_director_mappings.append((c_idx + 1, director_name, random.choice(titles)))

# Filter out duplicates (same director with multiple titles in the same company)
seen_mappings = set()
filtered_mappings = []
for c_id, d_name, title in company_director_mappings:
    if (c_id, d_name) not in seen_mappings:
        seen_mappings.add((c_id, d_name))
        filtered_mappings.append((c_id, d_name, title))

company_director_mappings = filtered_mappings

print(f"Generated {len(companies)} companies and {len(company_director_mappings)} director seats.")

# --- Execute SQL Inserts ---
try:
    print("Recreating tables with clean state...")
    execute("DROP TABLE IF EXISTS director CASCADE;")
    execute("DROP TABLE IF EXISTS company CASCADE;")
    
    execute("""
    CREATE TABLE company (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        industry VARCHAR(100)
    );
    """)
    execute("""
    CREATE TABLE director (
        id SERIAL PRIMARY KEY,
        company_id INT REFERENCES company(id),
        name VARCHAR(255) NOT NULL,
        title VARCHAR(100)
    );
    """)

    print("Inserting 50 companies...")
    # Batch insert 50 companies at once using a large string
    company_values = ", ".join([f"('{n}', '{i}')" for n, i in companies])
    execute(f"INSERT INTO company (name, industry) VALUES {company_values};")
    
    print("Inserting 100+ directors...")
    # Batch insert all director relationships
    director_values = ", ".join([f"({c_id}, '{n}', '{t}')" for c_id, n, t in company_director_mappings])
    execute(f"INSERT INTO director (company_id, name, title) VALUES {director_values};")

    print(f"\\n🎉 Database Scaled and Initialized Successfully with {len(company_director_mappings)} relationships!")
except Exception as e:
    print(f"\\n❌ Error: {e}")
