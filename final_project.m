function final_project
	clc; clear all;

	% get the xpath mechanism into the workspace
	import javax.xml.xpath.*
	factory = XPathFactory.newInstance;
	xpath = factory.newXPath;


	input_files = dir('texts/*.xml');
	% current_dir = pwd;

	for file = input_files(1)
		% disp(file.name)
		% file_URL = strcat('file://', current_dir, '/texts/', file.name)
		
		file_path = strcat('texts/', file.name);
		% xDoc = xmlread(fullfile(matlabroot, 'toolbox','matlab','general',file.name));
		% [pathstr,name,ext] = fileparts(file_path)
		% xDoc = xmlread(file_URL);
		xDoc = xmlread(file_path);
		% % allListitems = xDoc.getElementsByTagName('listitem')
		% xRoot = xDoc.getDocumentElement;
		% f = char(xRoot.getTextContent);
		% xDoc = parseXML(file_path);
		% fieldnames(xDoc)
		% xDoc.Children
		% cellData = struct2cell(xDoc)
		xmlwrite(xDoc)



		% compile and evaluate the XPath Expression
		expression = xpath.compile('TEI.2/text/body');
		bodyNode = expression.evaluate(xDoc, XPathConstants.NODE);
		text_body = bodyNode.getTextContent

	end

end