# Mamiya Employee Tracker

অফলাইন Attendance, OT ও Transport/Fare হিসাব রাখার Flutter অ্যাপ।

## ফোন দিয়েই APK বানানোর সহজ পদ্ধতি (GitHub Actions)

1. GitHub-এ একটি নতুন **Public repository** তৈরি করুন।
2. এই project-এর সব ফাইল upload করুন। `.github/workflows/build-apk.yml`-সহ upload করতে হবে।
3. Repository-তে **Actions** → **Build Android APK** নির্বাচন করুন।
4. **Run workflow** চাপুন।
5. Build শেষ হলে workflow-এর **Artifacts** অংশ থেকে `mamiya-employee-tracker-apk` ZIP download করুন।
6. ZIP খুলে `app-release.apk` ফোনে install করুন।

> প্রথমবার GitHub Actions Android platform files নিজে তৈরি করবে; ফোনে Flutter বা Android Studio লাগবে না।

## গুরুত্বপূর্ণ

- অ্যাপটি offline SQLite database ব্যবহার করে।
- OT সর্বোচ্চ 180 মিনিট (3 ঘণ্টা) হিসেবে সীমাবদ্ধ।
- একই তারিখে নতুন রেকর্ড দিলে আগের রেকর্ড replace হবে।
