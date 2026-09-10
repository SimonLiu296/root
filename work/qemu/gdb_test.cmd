set pagination off
set confirm off
target remote :1234
set architecture aarch64
echo CONNECTED
x/i 0xffffffc008227eac
detach
quit
