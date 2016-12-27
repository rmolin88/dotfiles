#include "clarifier.hpp"
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <iomanip>
#include <libconfig.h++>

#define OPT_MILLBALANCE "MillMaterialBalance"

void Usage();

int main(int argc, char const *argv[])
{
	try
	{
		if (argc < 2)
		{
			Usage();
			return 0;
		}  // End of "if (argc < 2)"

		if ((std::strncmp(argv[1], "-h", sizeof("-h")) == 0) || (std::strncmp(argv[1], "--help", sizeof("--help")) == 0))
		{ // Process help
			Usage();
			return 0;
		}

		libconfig::Config filecfg;
		filecfg.readFile(argv[1]);

		const libconfig::Setting &settRoot = filecfg.getRoot();
		if (settRoot.getLength() < 1)
		{
			std::cerr << "Main(): No main options in the config file\n";
			return -1;
		}

		const libconfig::Setting &settMill = settRoot[OPT_MILLBALANCE];
		int iNumOptions = settMill.getLength();

		try
		{
			for (int k=0; k<iNumOptions; k++) // Last option is complicated and composed
			{
				const libconfig::Setting &settBuff = settMill[k];
				std::string sPath = settBuff.getPath();
				int iValue;
				double dValue;

				if (settBuff.getType() == libconfig::Setting::TypeInt)
				{
					if (filecfg.lookupValue(sPath, iValue))
						std::cout << sPath << " = " << iValue << std::endl;
					else
						std::cout << "Couldnt decode " << sPath << std::endl;
				}
				else if (settBuff.getType() == libconfig::Setting::TypeFloat)
				{
					if (filecfg.lookupValue(sPath, dValue))
						std::cout << sPath << " = " << dValue << std::endl;
					else
						std::cout << "Couldnt decode " << sPath << std::endl;
				}
				else if (settBuff.getType() == libconfig::Setting::TypeGroup)
				{
					int iNumOpt = settBuff.getLength();
					for (int k1=0; k1 < iNumOpt; k1++)
					{
						const libconfig::Setting &settBuff1 = settBuff[k1];
						sPath = settBuff1.getPath();
						if (filecfg.lookupValue(sPath, dValue))
							std::cout << sPath << " = " << dValue << std::endl;
						else
							std::cout << "Couldnt decode " << sPath << std::endl;
					}
				}
				else
				{
					std::cout << "Setting " << sPath << " is of unexpected type" << std::endl;
					return -1;
				}
			}
		}
		catch(const libconfig::SettingNotFoundException &nfex)
		{
			std::cout << "Setting not found\n";
		}
		std::cout << "Hello, World!\n";
		return 0;
	}
	catch (const libconfig::FileIOException &fioex)
	{
		std::cerr << "I/O error while reading file.\n";
		return (EXIT_FAILURE);
	}
	catch (const libconfig::ParseException &pex)
	{
		std::cerr << "Parse error at " << pex.getFile() << ":" << pex.getLine() << " - " << pex.getError() << std::endl;
		return (EXIT_FAILURE);
	}
	catch (...)
	{
		std::cerr << "Main(): Unkown exception happened\n";
	}
}

void Usage()
{
	std::cout << "Please specify the name of the config file as the second argument\n";
}
