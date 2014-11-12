function final_project
	clc; clear all;

	% get the xpath mechanism into the workspace
	import javax.xml.xpath.*
	factory = XPathFactory.newInstance;
	xpath = factory.newXPath;


	input_files = dir('texts/*.xml'); % Reads only .xml files in the 'texts' directory
	% current_dir = pwd;


	work_freq_map = containers.Map();
	word_set = {};

	for file = input_files(1)%input_files'
		% disp(file.name)

		file_path = strcat('texts/', file.name);
		xDoc = xmlread(file_path);
		xmlwrite(xDoc);

		% compile and evaluate the XPath Expression
		expression = xpath.compile('TEI.2/text/body');
		bodyNode = expression.evaluate(xDoc, XPathConstants.NODE);
		% class(bodyNode.getTextContent)
		text_body = char(bodyNode.getTextContent); % Returns Matlab string
		% class(text_body)
		lines = regexp(text_body, '\n', 'split'); % Splits into lines
		% class(lines(3))

		word_freq_map = containers.Map();
		for i = 1:length(lines) % For every line in the work
			% lines{i}
			if isempty(lines{i})
				continue;
			end
			line = regexp(lines{i}, ' ', 'split');
			if ((length(line) == 1) && (line{1}(1) == '*')) % If there's only one word in the line.
				continue; % Ignore it
			else
				for j = 1:length(line) % For every word in the line
					if isKey(word_freq_map, line{j}) % Record in freq map
						word_freq_map(line{j}) = word_freq_map(line{j}) + 1;
					else
						word_freq_map(line{j}) = 1;
					end
					word_set = [word_set, line{j}];
				end
			end
		end
		% keys(word_freq_map);
		% values(word_freq_map)
		work_freq_map(file.name) = word_freq_map;

	end

	word_set = unique(word_set);
	word_set = char(word_set);

	big_X = zeros(length(word_set), length(input_files));

	key_set = keys(work_freq_map);

	for i = 1:length(key_set)
		current_work = work_freq_map(key_set{i});
		word_keys = keys(current_work);
		for j = 1:length(word_keys)
			curr_word = word_keys{j};
			curr_freq = current_work(curr_word);
			% index = find([word_set{:}] == curr_word)
			% class(curr_word)
			% class(word_set{1})
			% iscell(curr_word)
			% iscell(word_set)
			class(word_set)
			class(curr_word)
			% index = find(word_set==curr_word);
			index = strfind(word_set,curr_word);
			% index = strcmp(curr_word, word_set);
			big_X(index,i) = curr_freq;

		end
	end

	% big_X

end