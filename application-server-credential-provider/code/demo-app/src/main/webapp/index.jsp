<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CyberArk ASCP Demo</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Segoe UI', sans-serif;
            background-color: #f0f2f5;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }
        .card {
            background: white;
            border-radius: 10px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
            max-width: 480px;
            width: 100%;
            overflow: hidden;
        }
        .card-header {
            background: #004a99;
            color: white;
            padding: 1.8rem 2rem;
        }
        .card-header h1 {
            font-size: 1.3rem;
            font-weight: 600;
            letter-spacing: 0.3px;
        }
        .card-header p {
            margin-top: 0.4rem;
            font-size: 0.85rem;
            opacity: 0.85;
        }
        .card-body { padding: 1.8rem 2rem; }
        .scenario {
            font-size: 0.8rem;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.8px;
            color: #888;
            margin-bottom: 0.8rem;
        }
        .btn {
            display: block;
            padding: 13px 16px;
            border-radius: 6px;
            text-decoration: none;
            font-size: 0.95rem;
            font-weight: 500;
            transition: background 0.2s, transform 0.1s;
            margin-bottom: 0.6rem;
        }
        .btn:active { transform: scale(0.98); }
        .btn-before {
            background: #f4f5f7;
            color: #333;
            border: 1px solid #ddd;
        }
        .btn-before:hover { background: #e8eaed; }
        .btn-after {
            background: #004a99;
            color: white;
        }
        .btn-after:hover { background: #003d80; }
        .btn-label { font-size: 0.75rem; opacity: 0.7; display: block; margin-top: 2px; }
        .divider {
            text-align: center;
            color: #aaa;
            font-size: 0.8rem;
            margin: 0.8rem 0;
            position: relative;
        }
        .divider::before, .divider::after {
            content: '';
            position: absolute;
            top: 50%;
            width: 42%;
            height: 1px;
            background: #e5e5e5;
        }
        .divider::before { left: 0; }
        .divider::after { right: 0; }
        .note {
            margin-top: 1.4rem;
            padding: 0.8rem 1rem;
            background: #f0f6ff;
            border-left: 3px solid #004a99;
            border-radius: 4px;
            font-size: 0.8rem;
            color: #444;
            line-height: 1.5;
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="card-header">
            <h1>CyberArk ASCP &mdash; Zero Code Changes</h1>
            <p>Same servlet. Same JNDI lookup. Two very different credential sources.</p>
        </div>
        <div class="card-body">
            <div class="scenario">Choose a connection to test</div>

            <a href="customers" class="btn btn-before">
                Without CyberArk
                <span class="btn-label">Static password hardcoded in context.xml</span>
            </a>

            <div class="divider">vs</div>

            <a href="customers?source=cyberark" class="btn btn-after">
                With CyberArk ASCP
                <span class="btn-label">Credentials injected at runtime &mdash; no password in config</span>
            </a>

            <div class="note">
                Both buttons hit the same servlet and query the same database.
                The only difference is which DataSource Tomcat resolves &mdash; your application code never changes.
            </div>
        </div>
    </div>
</body>
</html>