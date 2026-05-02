# הכתובת החדשה תיראה כך:
RELEASE_URL="https://github.com/$GITHUB_USER/$GITHUB_REPO/releases/download/latest-build/demo-app.war"

function download_from_release() {
    echo "🌐 Pulling latest artifact from GitHub Releases..."
    if curl -sSfL "$RELEASE_URL" -o "/tmp/demo-app.war"; then
        echo "✅ Download successful!"
        return 0
    else
        echo "⚠️  Release artifact not found. Falling back to local methods."
        return 1
    fi
}