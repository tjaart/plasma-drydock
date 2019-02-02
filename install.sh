if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
cd build
cmake ../
make install
