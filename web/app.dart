/**
 * This application displays documentation generated by the docgen tool
 * found at dart-repo/dart/pkg/docgen. 
 * 
 * The Yaml file outputted by the docgen tool will be read in to 
 * generate [Page] and [Category] and [CategoryItem]. 
 * Pages, Categories and CategoryItems are used to format and layout the page. 
 */
// TODO(janicejl): Add a link to the dart docgen landing page in future. 
library dartdoc_viewer;

import 'dart:html';
import 'package:web_ui/web_ui.dart';
import 'package:dartdoc_viewer/data.dart';
import 'package:dartdoc_viewer/item.dart';
import 'package:dartdoc_viewer/read_yaml.dart';

// TODO(janicejl): YAML path should not be hardcoded. 
// Path to the YAML file being read in. 
const sourcePath = "../../test/yaml/large_test.yaml";

//Function to set the title of the current page. 
String get title => currentPage == null ? "" : currentPage.name;

// The homepage from which every [Item] can be reached.
@observable Item homePage;

// The current page being shown.
@observable Item currentPage;

/**
 * Changes the currentPage to the page of the item clicked.
 */
changePage(Item page, {bool isFromPopState: false}) {
  if (page != null) {
    if (!isFromPopState && currentPage != page) {
      var state = page.path;
      window.history.pushState(state, "", "/#$state");
    }
    currentPage = page;
  }
}

/**
 * Creates a list of [Item] objects from the [path] describing the
 * path to a particular [Item] object.
 */
List<Item> getBreadcrumbs(String path) {
  var breadcrumbs = [];
  var regex = new RegExp(r"(([a-zA-Z0-9]+)=?)/");
  var matches = regex.allMatches(path);
  var currentPath = "";
  matches.forEach((match) {
    currentPath = "$currentPath${match.group(0)}";
    breadcrumbs.add(pageIndex[currentPath]);
  });
  return breadcrumbs;
}

/**
 * Runs through the member structure and creates path information and
 * populates the [pageIndex] map for proper linking.
 */
void buildHierarchy(CategoryItem page, Item previous) {
  if (page is Item) {
    page.path = previous.path == null ?
        "${page.name}/" : "${previous.path}${page.name}/";
    pageIndex[page.path] = page;
    page.content.forEach((subChild) {
      if (subChild is Item || subChild is Category) {
        buildHierarchy(subChild, page);
      }
    });
  } else if (page is Category) {
    page.content.forEach((subChild) {
      buildHierarchy(subChild, previous);
    });
  }
}

// Builds hierarchy and sets up listener for browser navigation.
main() {
  var sourceYaml = getYamlFile(sourcePath);
  sourceYaml.then((response) {
    currentPage = loadData(response).first;
    homePage = currentPage;
    buildHierarchy(homePage, homePage);
  });
  
  // Handles browser navigation.
  window.onPopState.listen((event) {
    if (event.state != null) {
      if (event.state != "") {
        changePage(pageIndex[event.state], isFromPopState: true);
      } 
    } else {
      changePage(homePage, isFromPopState: true);
    }
  });
}