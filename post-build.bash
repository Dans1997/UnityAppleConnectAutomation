!/bin/bash
#/BUILD_PATH/****/.build/last/$TARGET_NAME/build.ipa
echo "Uploading IPA to Appstore Connect..."

# Log build paths
echo "Build Path: $WORKSPACE/.build/last/$TARGET_NAME/build.ipa"
path="$WORKSPACE/.build/last/$TARGET_NAME/build.ipa"

# Decrypt the encrypted .p8 file
encrypted_key_path="$WORKSPACE/Assets/PrivateKeys/authkey.p8.enc"
decrypted_key_path=~/private_keys/AuthKey_$API_KEY_ID.p8

# Step 1: Ensure private_keys directory exists
echo "Creating ~/private_keys/ directory..."
mkdir -p ~/private_keys/

# Step 2: Decrypt the .p8 file
which openssl || echo "OpenSSL is not installed on this system!"
echo "Decrypting $encrypted_key_path to $decrypted_key_path..."
if openssl aes-256-cbc -d -in "$encrypted_key_path" -out "$decrypted_key_path" -k "$ENCRYPTION_KEY"; then
    echo "Decryption succeeded. AuthKey placed in ~/private_keys/"
else
    echo "Decryption failed! Check the encryption key and file path."
    exit 1
fi

# Step 3: Upload IPA to App Store Connect
echo "Uploading IPA to Appstore Connect..."
if xcrun altool --upload-app -t ios -f "$path" \
    --apiKey "$API_KEY_ID" \
    --apiIssuer "$API_ISSUER_ID"; then
    echo "Upload IPA to Appstore Connect finished with success"
else
    echo "Upload IPA to Appstore Connect failed"
    exit 1
fi
