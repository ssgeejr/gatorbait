@echo off


set "$date=%date:~4%"
set "$date=%$date:/=%"
echo %$date%

:: Trim any possible trailing spaces (for safety)

:: Confirm completion
echo Export completed, results saved to: withOutMFAOnly_%$date%.csv

