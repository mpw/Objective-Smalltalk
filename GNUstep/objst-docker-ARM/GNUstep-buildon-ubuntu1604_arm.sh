#!/bin/bash

# Show prompt function
function showPrompt()
{
  if [ "$PROMPT" = true ] ; then
    echo -e "\n\n"
    read -p "${GREEN}Press enter to continue...${NC}"
  fi
}

# Set colors
GREEN=`tput setaf 2`
NC=`tput sgr0` # No Color

# Set to true to also build and install apps
APPS=true

# Set to true to pause after each build to verify successful build and installation
PROMPT=false

# Install Requirements
sudo apt update

echo -e "\n\n${GREEN}Installing dependencies...${NC}"

sudo apt -y install clang git libffi-dev libxml2-dev \
libgnutls28-dev libicu-dev libblocksruntime-dev  libpthread-workqueue-dev autoconf libtool \
libjpeg-dev libtiff-dev libffi-dev libcairo-dev libx11-dev libxt-dev libxft-dev

echo “Getting updated libstdc++6 for GLIBCXX for clang9”
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
sudo apt-get update
sudo apt-get install -y gcc-4.9
sudo apt-get install -y libstdc++6
echo “Getting clang9 binaries for Aarch64”
wget --no-clobber http://releases.llvm.org/9.0.0/clang+llvm-9.0.0-aarch64-linux-gnu.tar.xz
echo "Untarring/unxzipping (this step can take a while)..."
tar xf clang+llvm-9.0.0-aarch64-linux-gnu.tar.xz
cd clang+llvm-9.0.0-aarch64-linux-gnu/bin/
ln -s clang-9 clang++-9
cd ../../

export PATH=`pwd`/clang+llvm-9.0.0-aarch64-linux-gnu/bin/:$PATH
echo "export PATH=`pwd`/clang+llvm-9.0.0-aarch64-linux-gnu/bin/:\$PATH" >> ~/.bashrc

echo $PATH
# Set clang as compiler
export CC=clang-9
export CXX=clang++-9

wget --no-clobber https://github.com/Kitware/CMake/releases/download/v3.15.5/cmake-3.15.5.tar.gz
tar xfz cmake-3.15.5.tar.gz
cd cmake-3.15.5
./bootstrap -- -DCMAKE_BUILD_TYPE:STRING=Release
make -j2
sudo make install
cd ..

if [ "$APPS" = true ] ; then
  sudo apt -y install curl
fi

# Create build directory
mkdir GNUstep-build
cd GNUstep-build

export RUNTIME_VERSION=gnustep-2.0
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
export LD=/usr/bin/ld.gold
export LDFLAGS="-fuse-ld=gold -L/usr/local/lib"


# Checkout sources
echo -e "\n\n${GREEN}Checking out sources...${NC}"
git clone https://github.com/apple/swift-corelibs-libdispatch
git clone https://github.com/gnustep/libobjc2.git
cd libobjc2
 git submodule init
 git submodule sync
 git submodule update
cd ..

git clone https://github.com/gnustep/tools-make.git
git clone https://github.com/gnustep/libs-base.git
git clone https://github.com/gnustep/libs-gui.git
git clone https://github.com/gnustep/libs-back.git

if [ "$APPS" = true ] ; then
  git clone https://github.com/gnustep/apps-projectcenter.git
  git clone https://github.com/gnustep/apps-gorm.git
  git clone https://github.com/gnustep/apps-gworkspace.git
  git clone https://github.com/gnustep/apps-systempreferences.git
fi

showPrompt
set -e
# Build GNUstep make first time
echo -e "\n\n"
echo -e "${GREEN}Building GNUstep-make for the first time...${NC}"
cd tools-make
# git checkout `git rev-list -1 --first-parent --before=2017-04-06 master` # fixes segfault, should probably be looked at.
./configure --enable-debug-by-default --with-layout=gnustep  --enable-objc-arc  --with-library-combo=ng-gnu-gnu
make -j8
sudo -E make install

. /usr/GNUstep/System/Library/Makefiles/GNUstep.sh
echo ". /usr/GNUstep/System/Library/Makefiles/GNUstep.sh" >> ~/.bashrc
echo "export RUNTIME_VERSION=$RUNTIME_VERSION" >> ~/.bashrc

showPrompt

## Build libDIspatch
echo -e "\n\n"
echo -e "${GREEN}Building libdispatch...${NC}"
cd ../swift-corelibs-libdispatch
rm -Rf build
mkdir build && cd build
cmake .. -DCMAKE_C_COMPILER=${CC} \
	-DCMAKE_CXX_COMPILER=${CXX} \
	-DCMAKE_BUILD_TYPE=Release \
	-DUSE_GOLD_LINKER=YES
make -j2
sudo -E make install
sudo ldconfig


## Build libdispatch
#echo -e "\n\n"
#echo -e "${GREEN}Building libdispatch...${NC}"
#cd ../libdispatch
#rm -Rf build
#mkdir build && cd build
#../configure  --prefix=/usr
#make
#sudo make install
#sudo ldconfig

showPrompt

# Build libobjc2
echo -e "\n\n"
echo -e "${GREEN}Building libobjc2...${NC}"
cd ../../libobjc2
rm -Rf build
mkdir build && cd build
cmake ../ -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_ASM_COMPILER=clang -DTESTS=OFF
cmake --build .
sudo -E make install
sudo ldconfig

showPrompt

# Build GNUstep make second time
echo -e "\n\n"
echo -e "${GREEN}Building GNUstep-make for the second time...${NC}"
cd ../../tools-make
./configure --enable-debug-by-default --with-layout=gnustep --enable-objc-arc --with-library-combo=ng-gnu-gnu
make -j8
sudo -E make install

. /usr/GNUstep/System/Library/Makefiles/GNUstep.sh

showPrompt

# Build GNUstep base
echo -e "\n\n"
echo -e "${GREEN}Building GNUstep-base...${NC}"
cd ../libs-base/
./configure
make -j8
sudo -E make install

showPrompt

# Build GNUstep GUI
echo -e "\n\n"
echo -e "${GREEN} Building GNUstep-gui...${NC}"
cd ../libs-gui
./configure
make -j8
sudo -E make install

showPrompt

# Build GNUstep back
echo -e "\n\n"
echo -e "${GREEN}Building GNUstep-back...${NC}"
cd ../libs-back
./configure
make -j8
sudo -E make install

showPrompt

. /usr/GNUstep/System/Library/Makefiles/GNUstep.sh

if [ "$APPS" = true ] ; then
  echo -e "${GREEN}Building ProjectCenter...${NC}"
  cd ../apps-projectcenter/
  make -j8
  sudo -E make install

  showPrompt

  echo -e "${GREEN}Building Gorm...${NC}"
  cd ../apps-gorm/
  make -j8
  sudo -E make install

  showPrompt

  echo -e "\n\n"
  echo -e "${GREEN}Building GWorkspace...${NC}"
  cd ../apps-gworkspace/
  ./configure
  make -j8
  sudo -E make install

  showPrompt

  echo -e "\n\n"
  echo -e "${GREEN}Building SystemPreferences...${NC}"
  cd ../apps-systempreferences/
  make -j8
  sudo -E make install

fi

echo -e "\n\n"
echo -e "${GREEN}Install is done. Open a new terminal to start using.${NC}"
