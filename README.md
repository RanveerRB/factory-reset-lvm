sudo chmod +x init-factory-snapshot.sh

sudo ./init-factory-snapshot.sh

---

To reset the system in the future:
1. Boot from Ubuntu Live CD
2. Open terminal and run:
   sudo lvconvert --merge /dev/ubuntu-vg/root_factory_reset
   sudo reboot
