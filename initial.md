Tech stack: 
    Code: flutter web
    Auth: Clerk
    student_verify(@lpu.in): Brevo
    Profile_Data: Firebase
    Image_store: Cloudfare R2


Architecture:
    Firebase:
        State Management: Store these 20 profiles in a Flutter List variable.
            Desc: fetch 20 profiles at once (1 read operation per document, but fewer network calls).

    Cloudfare: 
        Use image_cropper in Flutter Don't just let users upload any photo. Force them to crop it to a specific aspect ratio (e.g., 4:5 for dating cards) inside the app.
           - Package: image_cropper + image_picker

        R2 gives you 10GB of storage. To make that last for thousands of users, you must compress images on the phone.

            Package: flutter_image_compress
            Target: Convert to WebP format, quality 70%. This turns a 5MB photo into ~50KB.
   

Optimisation:
    Ghost Mode: 
        Use CanvasKit: In your index.html, ensure you are using the CanvasKit renderer  for smooth 60fps swipes. The HTML renderer will lag on swiping cards.

        Pre-cache Images: Flutter has a built-in precacheImage function.
            Logic: While the user is looking at Card A, your code should be silently downloading the image for Card B in the background.

Key Implementation Points:

        Primary Authentication: Initial sign-up via personal Gmail using Clerk to ensure permanent account recovery.

        Desc:  After creating the account in users profile there will be warning to Verify there account by a @lpu.in mail id.

        Provisional Access: A strict 72-hour grace period is granted upon account creation, tracked via server timestamps.

        University Validation: Users must link a valid @lpu.in email address to verify student status.

        OTP Delivery: A secure 6-digit One-Time Password is generated and sent to the university email using the Brevo Transactional API (REST).

        Access Enforcement: If the is_student_verified flag remains false after 3 days, the system automatically suspends account access until verification is completed.