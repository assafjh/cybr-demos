<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CyberArk ASCP Demo</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; background-color: #f0f2f5; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
        .card { background: white; padding: 2rem; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); text-align: center; max-width: 400px; width: 100%; }
        h1 { color: #1c1e21; margin-bottom: 1.5rem; }
        .btn { display: block; background: #004a99; color: white; padding: 12px; margin: 10px 0; border-radius: 5px; text-decoration: none; transition: background 0.3s; }
        .btn:hover { background: #003366; }
        .btn-secondary { background: #6c757d; }
        .btn-secondary:hover { background: #5a6268; }
        .footer { margin-top: 20px; font-size: 0.85rem; color: #606770; }
    </style>
</head>
<body>
    <div class="card">
        <h1>ASCP Demo App</h1>
        <p>Select a method to retrieve database credentials:</p>
        
        <a href="zoo" class="btn btn-secondary">Standard Postgres DS</a>
        <a href="zoo?source=cyberark" class="btn">CyberArk Managed DS</a>
        
        <div class="footer">
            <p>Demonstrating zero-code-changes secret retrieval via CyberArk Application Server Credential Provider.</p>
        </div>
    </div>
</body>
</html>