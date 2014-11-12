function final_project
	clc; clear all;

	% get the xpath mechanism into the workspace
	import javax.xml.xpath.*
	factory = XPathFactory.newInstance;
	xpath = factory.newXPath;

	input_files = dir('texts/*.xml'); % Reads only .xml files in the 'texts' directory

	work_freq_map = containers.Map();
	word_set = {};
	authors_list = {};

	for file = input_files(1)%input_files'
		authors_list = [authors_list, strtok(file.name,'_')];
		file_path = strcat('texts/', file.name);
		xDoc = xmlread(file_path);
		xmlwrite(xDoc);

		% compile and evaluate the XPath Expression
		expression = xpath.compile('TEI.2/text/body');
		bodyNode = expression.evaluate(xDoc, XPathConstants.NODE);
		text_body = char(bodyNode.getTextContent); % Returns Matlab string
		lines = regexp(text_body, '\n', 'split'); % Splits into lines

		word_freq_map = containers.Map();
		for i = 1:length(lines) % For every line in the work
			if isempty(lines{i})
				continue;
			end
			line = regexp(lines{i}, ' ', 'split');
			if ((length(line) == 1) && (line{1}(1) == '*')) % If there's only one word in the line.
				continue; % Ignore it
			else
				for j = 1:length(line) % For every word in the line
					if isempty(line{j})
						continue;
					end
					if isKey(word_freq_map, line{j}) % Record in freq map
						word_freq_map(line{j}) = word_freq_map(line{j}) + 1;
					else
						word_freq_map(line{j}) = 1;
						word_set = [word_set, line{j}];
					end
				end
			end
		end
		work_freq_map(file.name) = word_freq_map;

	end

	word_set = unique(word_set);
	length(word_set)

	big_X = zeros(length(keys(work_freq_map)),length(word_set));

	works = keys(work_freq_map);

	for i = 1:length(works)
		current_work  = work_freq_map(works{i});
		words_in_work = keys(current_work);
		for j = 1:length(words_in_work)
			index = 0;
			for k = 1:length(word_set)
				if strcmp(char(word_set(k)), words_in_work{j})
					index = k;
					break;
				end
			end
			big_X(i,index) = current_work(words_in_work{j});

		end
	end

	X = big_X;
	token_list = word_set;
	labels = authors_list;

end