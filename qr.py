import qrcode

# Convert to string
qr_data = "ctrlF_app"

# Generate QR Code
qr = qrcode.make(qr_data)
qr.save("camera_qr.png")