import ctypes

def command_execute():
	os.system('copy -R soyrce_folder destination_folder')


def is_admin():
	try:
		return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False	
 	 	
if is_admin():	
	command_execute()	
else:	
	# Re-run the program with admin rights	
	ctypes.windll.shell32.ShellExecuteW(None, u"runas", unicode(sys.executable), unicode(""), None, 1)	
