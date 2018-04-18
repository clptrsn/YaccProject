
#include "simplecpp.h"

#include <fstream>
#include <iostream>
#include <cstring>
#include <dirent.h>

int main(int argc, char **argv)
{
   // Settings..

    std::string input_dir_name = "";
    std::string output_dir_name = "";

    for (int i = 1; i < argc; i++) {
        const char *arg = argv[i];
        if (*arg == '-') {
            char c = arg[1];
            if (c != 'O' && c != 'I')
                continue;  // Ignored
            char *value = arg[2] ? (argv[i] + 2) : argv[++i];
            switch (c) {
                case 'O': // define symbol
                    output_dir_name = std::string(value);
                    break;
                case 'I': // include path
                    input_dir_name = std::string(value);;
                    break;
            };
        }
    }

    if (output_dir_name == "" || input_dir_name == "") {
        std::cout << "Syntax:" << std::endl;
        std::cout << "simplecpp [options]" << std::endl;
        std::cout << "  -O          Output directory." << std::endl;
        std::cout << "  -I          Input directory." << std::endl;
        std::exit(0);
    }
 
    DIR* input_dir = opendir(input_dir_name.c_str());
    struct dirent* file = readdir(input_dir);

    while(file)
    {
        printf("Preprocessing: %s\n", file->d_name);
        if(strcmp(file->d_name + strlen(file->d_name) - 2, ".c") == 0)
        {
            simplecpp::DUI dui;
            dui.includePaths.push_back("/usr/include/");
            dui.includePaths.push_back("/usr/lib/gcc/x86_64-linux-gnu/6.3.0/include");

            std::string filename = std::string(file->d_name);
            // Perform preprocessing
            simplecpp::OutputList outputList;
            std::vector<std::string> files;
            std::ifstream f(input_dir_name + "/" + filename);
            simplecpp::TokenList rawtokens(f,files,filename,&outputList);
            rawtokens.removeComments();
            std::map<std::string, simplecpp::TokenList*> included = simplecpp::load(rawtokens, files, dui, &outputList);
            for (std::pair<std::string, simplecpp::TokenList *> i : included)
                i.second->removeComments();
            simplecpp::TokenList outputTokens(files);
            simplecpp::preprocess(outputTokens, rawtokens, files, included, dui, &outputList);

            // Output
            std::string output = outputTokens.stringify();

            FILE* outputFp = fopen((output_dir_name + "/" + filename + "_proc").c_str(), "w+");
            fprintf(outputFp, "%s", output.c_str());
            fclose(outputFp);
            // cleanup included tokenlists
            simplecpp::cleanup(included);
        }
        file = readdir(input_dir);
    }
}
