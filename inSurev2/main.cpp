
#include "simplecpp.h"

#include <fstream>
#include <iostream>
#include <cstring>

extern "C" char* preProcessFile(char *filename)
{
    // Settings..
    simplecpp::DUI dui;
	dui.includePaths.push_back("/usr/include/");
	dui.includePaths.push_back("/usr/lib/gcc/x86_64-linux-gnu/6.3.0/include");

    // Perform preprocessing
    simplecpp::OutputList outputList;
    std::vector<std::string> files;
    std::ifstream f(filename);
    simplecpp::TokenList rawtokens(f,files,filename,&outputList);
    rawtokens.removeComments();
    std::map<std::string, simplecpp::TokenList*> included = simplecpp::load(rawtokens, files, dui, &outputList);
    for (std::pair<std::string, simplecpp::TokenList *> i : included)
        i.second->removeComments();
    simplecpp::TokenList outputTokens(files);
    simplecpp::preprocess(outputTokens, rawtokens, files, included, dui, &outputList);

    // Output
    std::string output = outputTokens.stringify();

    // cleanup included tokenlists
    simplecpp::cleanup(included);

    return output.c_str();
}
