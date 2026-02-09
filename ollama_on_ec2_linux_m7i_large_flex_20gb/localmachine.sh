chmod 400 ~/Downloads/firstEC2.pem
ssh -i ~/Downloads/firstEC2.pem -L 11434:localhost:11434 ubuntu@54.173.108.23