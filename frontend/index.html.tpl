<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Serverless API Demo</title>
    <script type="module">
        import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';
        mermaid.initialize({ startOnLoad: true, theme: 'dark', securityLevel: 'loose' });
    </script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&display=swap');
        
        :root {
            --bg: #0f111a;
            --surface: rgba(255, 255, 255, 0.05);
            --border: rgba(255, 255, 255, 0.1);
            --primary: #6366f1;
            --primary-hover: #4f46e5;
            --secondary: #ec4899;
            --secondary-hover: #be185d;
            --text: #f8fafc;
            --text-muted: #94a3b8;
        }

        body {
            font-family: 'Inter', sans-serif;
            background-color: var(--bg);
            color: var(--text);
            margin: 0;
            padding: 40px 20px;
            display: flex;
            flex-direction: column;
            align-items: center;
            min-height: 100vh;
            background-image: 
                radial-gradient(circle at 15% 50%, rgba(99, 102, 241, 0.15), transparent 25%),
                radial-gradient(circle at 85% 30%, rgba(236, 72, 153, 0.15), transparent 25%);
        }

        h1 {
            font-size: 2.5rem;
            font-weight: 800;
            background: linear-gradient(to right, #818cf8, #c084fc);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 30px;
            text-align: center;
        }

        .container {
            width: 100%;
            max-width: 800px;
            display: flex;
            flex-direction: column;
            gap: 20px;
        }

        .card {
            background: var(--surface);
            backdrop-filter: blur(10px);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 24px;
            box-shadow: 0 4px 24px -1px rgba(0, 0, 0, 0.2);
            transition: transform 0.2s, box-shadow 0.2s;
            animation: fadeIn 0.3s ease-in-out;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }

        h2 {
            margin-top: 0;
            font-size: 1.25rem;
            border-bottom: 1px solid var(--border);
            padding-bottom: 12px;
            margin-bottom: 16px;
        }

        button {
            background: var(--primary);
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 8px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
        }

        button:hover {
            background: var(--primary-hover);
        }
        
        button:active {
            transform: scale(0.98);
        }

        .btn-secondary {
            background: var(--secondary);
        }
        .btn-secondary:hover {
            background: var(--secondary-hover);
        }

        .btn-back {
            background: transparent;
            color: var(--primary);
            padding: 0;
            margin-bottom: 16px;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }
        .btn-back:hover {
            background: transparent;
            color: var(--primary-hover);
            text-decoration: underline;
        }

        /* Lists */
        .list { display: flex; flex-direction: column; gap: 12px; }
        .list-item {
            background: rgba(0,0,0,0.2);
            padding: 16px;
            border-radius: 8px;
            display: flex;
            flex-direction: column;
            gap: 12px;
            border: 1px solid transparent;
            transition: border-color 0.2s;
        }
        .list-item:hover { border-color: var(--primary); }
        
        .role-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: rgba(255,255,255,0.03);
            padding: 8px 12px;
            border-radius: 6px;
            margin-left: 20px;
        }

        .title { font-weight: 600; font-size: 1.1rem; }
        .subtitle { font-size: 0.85rem; color: var(--text-muted); }
        .link { color: var(--primary); cursor: pointer; text-decoration: none; }
        .link:hover { text-decoration: underline; color: var(--primary-hover); }

        .form-group {
            display: flex;
            gap: 10px;
            margin-top: 10px;
        }
        input[type="text"] {
            background: rgba(0,0,0,0.3);
            border: 1px solid var(--border);
            color: white;
            padding: 8px 12px;
            border-radius: 6px;
            flex: 1;
            font-family: inherit;
        }
        input:focus { outline: none; border-color: var(--primary); }
    </style>
</head>
<body>

    <h1>Director Dashboard</h1>
    
    <div class="container">
        
        <!-- Dashboard Intro (Home View) -->
        <div class="card" id="homeView">
            <h2>Welcome to the Demo</h2>
            <p style="color: var(--text-muted); font-size: 0.95rem; margin-bottom: 24px;"></p>
            
            <div style="margin: 0 0 24px 0; background: rgba(0,0,0,0.2); border-radius: 8px; border: 1px solid var(--border); overflow: hidden;">
                <div class="mermaid" style="display:flex; justify-content:center; padding: 20px;">
graph TD
    User(["👨‍💻 End User Browser"]) -->|"HTTPS"| S3["🪣 AWS S3 Bucket<br/>Static Website Hosting"]
    
    subgraph AWS_Cloud ["☁️ AWS Cloud"]
        S3 -->|"CORS APIs"| APIGW["🚪 Amazon API Gateway<br/>HTTP API & Routing to Mock APIGEE"]
        APIGW -->|"Proxy Invoke"| Lambdas["⚡ AWS Lambda<br/>Microservices"]
        
        subgraph Security ["🛡️ Security Context"]
            IAM["🔑 AWS IAM Roles<br/>Execution Policies"]
            SecretsManager["🔐 AWS Secrets Manager<br/>Database Credentials"]
        end
        
        Lambdas -.->|"Assume"| IAM
        Lambdas -.->|"Retrieve"| SecretsManager
        
        subgraph DB_Layer ["🗄️ Database Layer (VPC)"]
            DataAPI["🔌 Amazon RDS Data API<br/>Stateless HTTPS"]
            Aurora[("🐘 Amazon Aurora Serverless <br/>PostgreSQL Cluster")]
        end
        
        Lambdas -->|"Execute"| DataAPI
        DataAPI -->|"Manage"| Aurora
    end

    style AWS_Cloud fill:none,stroke:#6366f1,stroke-dasharray:5,color:#fff
    style Security fill:none,stroke:#94a3b8,color:#fff
    style DB_Layer fill:none,stroke:#3b82f6,color:#fff

    style User fill:none,stroke:#ec4899,color:#fff
    style S3 fill:none,stroke:#10b981,color:#fff
    style APIGW fill:none,stroke:#8b5cf6,color:#fff
    style Lambdas fill:none,stroke:#f59e0b,color:#fff
    style IAM fill:none,stroke:#64748b,color:#fff
    style SecretsManager fill:none,stroke:#ef4444,color:#fff
    style DataAPI fill:none,stroke:#06b6d4,color:#fff
    style Aurora fill:none,stroke:#3b82f6,color:#fff
                </div>
            </div>

            <div style="display: flex; gap: 12px; flex-wrap: wrap;">
                <button onclick="fetchCompanies()">🏢 List All Companies</button>
                <button class="btn-secondary" onclick="fetchAllDirectors()">👤 List All Directors</button>
            </div>
        </div>

        <!-- Companies Output -->
        <div class="card" id="companiesView" style="display: none;">
            <button class="btn-back" onclick="showView('homeView')">← Back to Dashboard</button>
            <h2>Companies Database</h2>
            <div class="list" id="companiesList"></div>
        </div>

        <!-- Single Company Directors Output -->
        <div class="card" id="companyDirectorsView" style="display: none;">
            <button class="btn-back" onclick="showView('companiesView')">← Back to Companies</button>
            <h2>Directors for <span id="selectedCompanyName" style="color:var(--primary)">...</span></h2>
            <div class="list" id="companyDirectorsList"></div>
            
            <div id="companyUpdateForm" style="display:none; margin-top:20px; padding-top:20px; border-top: 1px solid var(--border);">
                <h4>Update <span id="companyEditingDirector" style="color:var(--text-muted)"></span></h4>
                <div class="form-group" style="flex-direction:column; gap:8px;">
                    <input type="text" id="companyNewTitleInput" placeholder="New Title">
                    <input type="text" id="companyNewAddressInput" placeholder="New Address">
                    <button onclick="submitUpdate('company')">Save Update inside Aurora</button>
                </div>
            </div>
        </div>

        <!-- Global Directors / Director Profile Output -->
        <div class="card" id="groupedDirectorsView" style="display: none;">
            <button class="btn-back" id="backToHomeBtn" onclick="showView('homeView')">← Back to Dashboard</button>
            <button class="btn-back" id="backToCompanyBtn" onclick="showView('companyDirectorsView')" style="display:none;">← Back to Company</button>
            
            <h2 id="groupedDirectorsTitle">Global Directors Directory</h2>
            <div class="list" id="groupedDirectorsList"></div>
            
            <div id="groupedUpdateForm" style="display:none; margin-top:20px; padding-top:20px; border-top: 1px solid var(--border);">
                <h4>Update Role for <span id="groupedEditingDirector" style="color:var(--text-muted)"></span></h4>
                <div class="form-group" style="flex-direction:column; gap:8px;">
                    <input type="text" id="groupedNewTitleInput" placeholder="New Title">
                    <input type="text" id="groupedNewAddressInput" placeholder="New Address">
                    <button onclick="submitUpdate('grouped')">Save Update inside Aurora</button>
                </div>
            </div>
        </div>
    </div>

    <script>
        const API_BASE = '${api_base_url}';
        
        // State
        let currentCompanyId = null;
        let currentCompanyNameStr = null;
        let currentDirectorId = null; // For editing role
        let currentProfileContext = null; // 'all' or 'profile:NAME'
        
        function escapeHtml(unsafe) {
            return (unsafe||"").toString()
                 .replace(/&/g, "&amp;")
                 .replace(/</g, "&lt;")
                 .replace(/>/g, "&gt;")
                 .replace(/"/g, "&quot;")
                 .replace(/'/g, "&#039;");
        }

        window.addEventListener('popstate', (event) => {
            if (event.state) {
                const { action, params } = event.state;
                if (action === 'home') showView('homeView', false);
                else if (action === 'companies') fetchCompanies(false);
                else if (action === 'companyDirectors') fetchDirectors(params.id, params.name, false);
                else if (action === 'allDirectors') fetchAllDirectors(false);
                else if (action === 'profile') fetchDirectorProfile(params.name, params.fromCompany, false);
            } else {
                showView('homeView', false);
            }
        });

        function showView(viewId, pushHistory = true, stateObj = null) {
            ['homeView', 'companiesView', 'companyDirectorsView', 'groupedDirectorsView'].forEach(id => {
                document.getElementById(id).style.display = (id === viewId) ? 'block' : 'none';
            });
            window.scrollTo({ top: 0, behavior: 'smooth' });
            
            if (pushHistory) {
                window.history.pushState(stateObj || { action: 'home' }, '', '');
            }
        }

        async function fetchAPI(endpoint, method = 'GET', body = null) {
            const opts = { method, headers: {} };
            if (body) {
                opts.headers['Content-Type'] = 'application/json';
                opts.body = JSON.stringify(body);
            }
            try {
                const res = await fetch(API_BASE + endpoint, opts);
                if (!res.ok) throw new Error('API Error: ' + res.status);
                return await res.json();
            } catch (err) {
                alert(err.message + "\\n\\nPlease make sure Terraform applied the configuration.");
                console.error(err);
            }
        }

        // ==========================================
        // COMPANIES
        // ==========================================
        async function fetchCompanies(pushHistory = true) {
            const btn = document.querySelector('#homeView button');
            const originalText = btn.innerHTML;
            btn.innerHTML = 'Loading...';

            const data = await fetchAPI('/companies');
            btn.innerHTML = originalText;
            if (!data) return;
            
            showView('companiesView', pushHistory, { action: 'companies' });
            const list = document.getElementById('companiesList');
            list.innerHTML = '';
            
            data.companies.forEach(c => {
                const el = document.createElement('div');
                el.className = 'list-item';
                el.style.flexDirection = 'row';
                el.style.justifyContent = 'space-between';
                el.style.alignItems = 'center';
                
                el.innerHTML = `
                    <div style="display:flex; flex-direction:column; gap:4px">
                        <span class="title">🏢 $${escapeHtml(c.name)}</span>
                        <span class="subtitle">Industry: $${escapeHtml(c.industry)}</span>
                    </div>
                    <div>
                        <button style="padding: 6px 12px; font-size:0.8rem;" onclick="fetchDirectors($${c.id}, '$${escapeHtml(c.name)}')">View Directors</button>
                    </div>
                `;
                list.appendChild(el);
            });
        }

        // ==========================================
        // DIRECTORS FOR A COMPANY (Flat List)
        // ==========================================
        async function fetchDirectors(companyId, companyName, pushHistory = true) {
            currentCompanyId = companyId;
            currentCompanyNameStr = companyName;
            
            document.getElementById('selectedCompanyName').innerText = companyName;
            
            const data = await fetchAPI(`/companies/$${companyId}/directors`);
            if (!data) return;

            showView('companyDirectorsView', pushHistory, { action: 'companyDirectors', params: {id: companyId, name: companyName} });
            document.getElementById('companyUpdateForm').style.display = 'none';

            const list = document.getElementById('companyDirectorsList');
            list.innerHTML = '';

            if(!data.directors || data.directors.length === 0) {
                 list.innerHTML = '<p class="subtitle" style="text-align:center;">No directors found.</p>';
                 return;
            }

            data.directors.forEach(d => {
                const el = document.createElement('div');
                el.className = 'list-item';
                el.style.flexDirection = 'row';
                el.style.justifyContent = 'space-between';
                el.style.alignItems = 'center';
                
                el.innerHTML = `
                    <div style="display:flex; flex-direction:column; gap:4px">
                        <span class="title">👤 <span class="link" onclick="fetchDirectorProfile('$${escapeHtml(d.name)}', true)">$${escapeHtml(d.name)}</span></span>
                        <span class="subtitle">Title: $${escapeHtml(d.title)}</span>
                        <span class="subtitle" style="font-style: italic;">$${escapeHtml(d.address)}</span>
                    </div>
                    <div>
                        <button style="padding: 6px 12px; font-size:0.8rem; background: rgba(255,255,255,0.1); border: 1px solid var(--border);" onclick="showUpdateForm('company', $${d.id}, '$${escapeHtml(d.name)}', '$${escapeHtml(d.title)}', '$${escapeHtml(d.address)}')">Edit</button>
                    </div>
                `;
                list.appendChild(el);
            });
        }

        // ==========================================
        // GLOBAL / PROFILE DIRECTORS (Grouped List)
        // ==========================================
        async function fetchAllDirectors(pushHistory = true) {
            currentProfileContext = 'all';
            const btn = document.querySelector('#homeView button.btn-secondary');
            const originalText = btn.innerHTML;
            btn.innerHTML = 'Loading...';

            const data = await fetchAPI('/directors');
            btn.innerHTML = originalText;
            if (!data) return;

            document.getElementById('groupedDirectorsTitle').innerText = 'Global Directors Directory';
            document.getElementById('backToHomeBtn').style.display = 'inline-flex';
            document.getElementById('backToCompanyBtn').style.display = 'none';

            showView('groupedDirectorsView', pushHistory, { action: 'allDirectors' });
            document.getElementById('groupedUpdateForm').style.display = 'none';
            renderGroupedDirectors(data.directors);
        }

        async function fetchDirectorProfile(directorName, fromCompanyView = false, pushHistory = true) {
            currentProfileContext = `profile:$${directorName}`;
            
            const data = await fetchAPI(`/directors/profile/$${encodeURIComponent(directorName)}`);
            if (!data) return;

            document.getElementById('groupedDirectorsTitle').innerText = `$${directorName}'s Profile`;
            
            if (fromCompanyView) {
                document.getElementById('backToHomeBtn').style.display = 'none';
                document.getElementById('backToCompanyBtn').style.display = 'inline-flex';
            } else {
                document.getElementById('backToHomeBtn').style.display = 'inline-flex';
                document.getElementById('backToCompanyBtn').style.display = 'none';
            }

            showView('groupedDirectorsView', pushHistory, { action: 'profile', params: {name: directorName, fromCompany: fromCompanyView} });
            document.getElementById('groupedUpdateForm').style.display = 'none';
            renderGroupedDirectors([data.profile]);
        }

        function renderGroupedDirectors(groupedArray) {
            const list = document.getElementById('groupedDirectorsList');
            list.innerHTML = '';

            if(!groupedArray || groupedArray.length === 0) {
                 list.innerHTML = '<p class="subtitle" style="text-align:center;">No directors found.</p>';
                 return;
            }

            groupedArray.forEach(profile => {
                const el = document.createElement('div');
                el.className = 'list-item';
                
                let html = `<div class="title" style="margin-bottom:8px">👤 $${escapeHtml(profile.name)}</div>`;
                
                profile.roles.forEach(role => {
                    html += `
                    <div class="role-row" style="flex-wrap: wrap;">
                        <div style="display:flex; flex-direction:column; gap:2px">
                            <div>
                                <span class="subtitle">🏢 <span class="link" onclick="fetchDirectors($${role.company_id}, '$${escapeHtml(role.company_name)}')">$${escapeHtml(role.company_name)}</span></span>
                                <span class="subtitle" style="margin-left:8px; color:var(--text)">($${escapeHtml(role.title)})</span>
                            </div>
                            <span class="subtitle" style="font-style: italic; font-size: 0.75rem;">$${escapeHtml(role.address)}</span>
                        </div>
                        <button style="padding: 4px 8px; font-size:0.75rem; background: rgba(255,255,255,0.05); border: 1px solid var(--border); border-radius:4px" onclick="showUpdateForm('grouped', $${role.id}, '$${escapeHtml(profile.name)}', '$${escapeHtml(role.title)}', '$${escapeHtml(role.address)}')">Edit</button>
                    </div>
                    `;
                });
                
                el.innerHTML = html;
                list.appendChild(el);
            });
        }

        // ==========================================
        // UPDATE FORM LOGIC
        // ==========================================
        function showUpdateForm(viewType, roleId, name, currentTitle, currentAddress) {
            currentDirectorId = roleId;
            const prefix = viewType === 'company' ? 'company' : 'grouped';
            
            document.getElementById(`$${prefix}UpdateForm`).style.display = 'block';
            document.getElementById(`$${prefix}EditingDirector`).innerText = name;
            document.getElementById(`$${prefix}NewTitleInput`).value = currentTitle;
            document.getElementById(`$${prefix}NewAddressInput`).value = currentAddress;
            setTimeout(() => document.getElementById(`$${prefix}NewTitleInput`).focus(), 100);
            window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' });
        }

        async function submitUpdate(viewType) {
            const prefix = viewType === 'company' ? 'company' : 'grouped';
            const newTitle = document.getElementById(`$${prefix}NewTitleInput`).value;
            const newAddress = document.getElementById(`$${prefix}NewAddressInput`).value;
            if(!newTitle && !newAddress) return alert("Title or Address required");
            
            const btn = document.querySelector(`#$${prefix}UpdateForm button`);
            const originalText = btn.innerText;
            btn.innerText = 'Updating...';
            
            const data = await fetchAPI(`/directors/$${currentDirectorId}`, 'PUT', { title: newTitle, address: newAddress });
            btn.innerText = originalText;
            
            if(data) {
                document.getElementById(`$${prefix}UpdateForm`).style.display = 'none';
                
                // Reload the current view intelligently
                if (viewType === 'company') {
                    await fetchDirectors(currentCompanyId, currentCompanyNameStr);
                } else {
                    if (currentProfileContext === 'all') {
                        await fetchAllDirectors();
                    } else if (currentProfileContext.startsWith('profile:')) {
                        const dName = currentProfileContext.split(':')[1];
                        await fetchDirectorProfile(dName, document.getElementById('backToCompanyBtn').style.display !== 'none');
                    }
                }
            }
        }
    </script>
</body>
</html>
