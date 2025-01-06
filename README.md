# Automating IPA Upload to App Store Connect via Unity Cloud Build

This guide provides step-by-step instructions for securely storing your App Store Connect `.p8` authentication file in a Unity project, encrypting it for Git storage, and automating its decryption and usage during Unity Cloud Build.

This solution was derived from Jonathan Lemos' post on Unity Support, which outlines how to upload an IPA from Build Automation to Apple Connect. However, the original post did not provide clear guidance on how or where to make the .p8 file available in Unity Cloud. Please note that this solution is functional, but it may not be the most secure or optimal approach. For further details, you can refer to the original post [here](https://support.unity.com/hc/en-us/articles/27576236407956-How-to-upload-an-IPA-from-Build-Automation-to-Apple-Connect).

This tutorial assumes you already have generated `.p8` file required to upload `.ipa` files to Apple Connect via a CLI (`xcrun`).

OpenSSL is just one of the available options for encrypting a .p8 file. While it is a popular and widely-used toolkit for encryption, there are other methods and libraries that can be used depending on your specific requirements and platform.

Sensitive information was hidden with `****`.

## **Setup Overview**
1. Encrypt your `.p8` file for secure storage in your repository.
2. Add scripts to Unity Cloud Build to decrypt the file and prepare the environment for IPA uploads.
3. Automate the upload process with Unity Cloud Build.

---

## **Encryption Process**
### **Step 1: Encrypt the `.p8` File**
Run the following command on your local machine to encrypt the `.p8` file:
```bash
encrypt_key="your_secure_password"
openssl aes-256-cbc -in AuthKey.p8 -out AuthKey.p8.enc -k "$encrypt_key"
```

### **Step 2: Add Encrypted File to Unity Project**
Place the `AuthKey.p8.enc` file in your Unity project directory, e.g., `Assets/PrivateKeys/`. Add this file to your Git repository so that Unity Build Automation can find it later on.

---

## **Unity Cloud Build Setup**
### **Step 3: Add Environment Variables**
In Unity Cloud Build:
1. Navigate to **Cloud Build Settings** for your project.
2. Add the following environment variables:
   - `ENCRYPTION_KEY`: Your encryption password.
   - `API_KEY_ID`: Your App Store Connect API Key ID.
   - `API_ISSUER_ID`: Your App Store Connect API Issuer ID.

In more detail: First, go to Unity Cloud and select Projects. Then, navigate to the DevOps section. Under DevOps, select Build Automation. From there, click on Configurations. Find the iOS configuration you want to use, and select it. Once you’re in the correct configuration, you can add the necessary environment variables to be used in your build process (advanced settings section).

### **Step 4: Add Post-Build Script**
Create a script named `post-build.bash` in your Unity project:

```bash
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
```
Add the script in your Unity Cloud Build Configuration in Script Hooks -> Post-Build Script. The value should be something like `Assets/<relative_folder>/post-build.bash`.

Make sure the script is executable:
```bash
chmod +x post-build.bash
```
---

## **Testing and Validation**
1. **Commit Changes**: Push your encrypted `.p8` file, `post-build.bash` to your repository.
2. **Trigger a Build**: Run a new Unity Cloud Build.
3. **Check Logs**: Ensure that decryption is successful and the upload completes without errors.

---

## **Troubleshooting**
- **Error: OpenSSL Not Found**: Verify that `openssl` is installed on Unity Cloud Build using `which openssl`. If unavailable, use alternatives like `gpg` or `base64` for encryption.
- **Failed to Decrypt**: Double-check the `ENCRYPTION_KEY` in Unity Cloud Build matches the one used for encryption.
- **API Authentication Issues**: Ensure `API_KEY_ID` and `API_ISSUER_ID` are correct and associated with your App Store Connect account.

---

## **Best Practices**
- **Secure Storage**: Never commit unencrypted `.p8` files to your repository.
- **Environment Variables**: Use Unity Cloud Build environment variables for sensitive information.
