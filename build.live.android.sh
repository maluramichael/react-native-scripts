#!/bin/bash
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
keystore="" # name of your keystore file. project.keystore
keystoreAlias="" # name of the alias inside your keystore.
bundleIdentifier="" # de.mycompany.myawesomeapp
apkName="" # MyAwesomeAppLive without .apk
appDestination="" # final destination for your app. $HOME/Desktop/Apps/MyAwesomeApp/Live
gradlewCommand="" # assembleRelease
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------

if [ -z ${ANDROID_KEYSTORES} ]
then 
  echo "Environment variable ANDROID_KEYSTORES is not defined"
  exit 1
else 
  echo "Environment variable ANDROID_KEYSTORES is set to '$ANDROID_KEYSTORES'"
fi

keystorePath="$ANDROID_KEYSTORES/$keystore"

if [ -e $keystorePath ]
then
  echo "Found keystore $keystorePath"
else
  echo "Keystore does not exist $keystorePath"
  exit 1
fi

echo "Change to android directory"
cd ../android

echo "Remove old build files"
rm app/build/outputs/apk/*

echo "Build liveRelease apk..."
./gradlew $gradlewCommand

error=0
error=$?
if [ "$error" != "0" ]
then
  echo "Could not buld apk"
  exit 1
fi

unsignedApk=`ls app/build/outputs/apk/* | tail -1`

echo "Sign apk with keystore..."
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore $keystorePath $unsignedApk $keystoreAlias

echo "build final liveRelease apk for device..."
zipalign -f -v 4 $unsignedApk "$apkName.apk"

DATE=`date '+%Y-%m-%d-%H-%M-%S'`
mkdir -p $appDestination
appDestinationFullPath="$appDestination/$apkName.$DATE.apk"
echo "Copy app to $appDestinationFullPath"
mv "$apkName.apk" $appDestinationFullPath

devices=`adb devices | grep -v List | grep -v '^$' | wc -l | awk '{print $1}'`
if [ "$devices" != "0" ] 
then
  echo "Connected devices $devices"
  echo "Remove apk..."
  adb uninstall $bundleIdentifier
  echo "Install apk on device..."
  adb install $apkName
fi
