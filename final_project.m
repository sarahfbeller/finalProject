function final_project
	clc; clear all;	tic; 													% Clear variables and start stopwatch.
	
	import javax.xml.xpath.*												% Get the xPath mechanism into the workspace.
	factory 		 = XPathFactory.newInstance;
	xpath 			 = factory.newXPath;

	input_directory  = 'test/';
	noun_endings     = {'as' 'ou' 'an' 'a' 'ain' 'ai' 'wn' 'ais' 'hs' ...
						'h' 'hn' 'os' 'on' 'e' 'w' 'oin' 'ous' 'oi' 'ws' ...
						'us' 'uos' 'ui' 'un' 'u' 'ues' 'uwn' 'usi' 'is' ...
						'ews' 'ei' 'in' 'i' 'eis' 'ewn' 'esi' 'us'};
	verb_endings     = {'w' 'eis' 'ei' 'omen' 'ete' 'ousi' 'ousin' ...
						'wmen' 'hte' 'wsi' 'wsin' 'oimi' 'ois' 'oi' ...
						'oimen' 'oite' 'oien' 'etw' 'ontwn' 'wsan' 'ein' ...
						'wn' 'ousa' 'on' 'as' 'asa' 'an'};
	% s and then verb ending -> cut s
	% ignored middle and passive for now
	% figure out - iota subscript with a, h, q, hs, 

	endings 		 = [noun_endings verb_endings];							% Combine noun and verb endings
	[dummy, index]   = sort(cellfun('size', endings, 2), 'descend');		% Order by size, largest to smallest.
  	endings     	 = endings(index); 

	% word_freq_map  = containers.Map();
	% work_freq_map  = containers.Map();
	% word_set       = {};

	token_list       = {};													% Initialize token_list.
	authors_list     = {};													% Initialize author_list (Y).
	X                = zeros(0,0);											% Initialize X matrix.
	input_files      = dir(strcat(input_directory, '*.xml')); 				% Read only .xml files.
	file_num         = 1;

	for file = input_files'													% For every file in the input directory:
		authors_list = [authors_list, strtok(file.name,'_')];				% Get this author to author_list.
		file_path    = strcat(input_directory, file.name);
		xDoc 	     = xmlread(file_path);
		xmlwrite(xDoc);

		expression   = xpath.compile('TEI.2/text/body');					% Compile the xPath Expression.
		bodyNode     = expression.evaluate(xDoc, XPathConstants.NODE);		% Evaluate the xPath Expression.
		text_body    = char(bodyNode.getTextContent); 						% Returns Matlab string.
		lines 	     = regexp(text_body, '\n', 'split'); 					% Split into lines.
		lines        = regexprep(lines,'[\/\\=|,.:]','');					% Take out accents.

		[m,n] 		 = size(X);
		X 			 = [X; zeros(1,n)];

		for i = 1:length(lines) 											% For every line in the work:
			if isempty(lines{i})											% Skip empty lines.
				continue;
			end
			line = regexp(lines{i}, ' ', 'split');							% Split line into words.

			if ((length(line) == 1) && (line{1}(1) == '*'))					% Skip one-word lines (i.e. speakers).
				continue;
			else

				for j = 1:length(line) 										% For every word in the line:

					if (isempty(line{j}) || (line{j}(1) == '*'))			% Skip empty or capital words.
						continue;
					end

					for k = length(endings{1}) : -1 : length(endings{end})  % Stem word.
						if (length(line{j}) > k)
							if ~isempty(find(strcmp(line{j}(end-k+1:end), endings)))
								line{j} = line{j}(1:end-k);
								break;
							end
						end
					end

					index = find(strcmp(line{j}, token_list));				% Find word in token_list.
					if isempty(index)										% If word is a new word:
						token_list = [token_list, line{j}]; 				% Add word to token list.
						X(file_num, size(token_list)) = 1;  		 		% Add '1' to X matrix.
					else
						X(file_num, index) = X(file_num, index) + 1; 		% Increment training matrix.
					end

					% if (length(line{j}) > 5) 								% Primitive stemmer
					% 	line{j} = line{j}(1:end-3);
					% end

					% noun_index = find(strcmp(line{j}, noun_endings));
					% verb_index = find(strcmp(line{j}, verb_endings));
					% if (~isempty(noun_index))
					% 	line{j} = line{j}(1:end-noun_index);
					% elseif(~isempty(verb_index))
					% 	line{j} = line{j}(1:end-verb_index);
					% end

					% if isKey(word_freq_map, line{j}) % Record in freq map
					% 	word_freq_map(line{j}) = word_freq_map(line{j}) + 1;
					% else
					% 	word_freq_map(line{j}) = 1;
					% 	word_set = [word_set, line{j}];
					% end
				end
			end
		end
		% work_freq_map(file.name) = word_freq_map;
		file_num = file_num + 1;
	end
	fprintf('Finished populating X in %d minutes and %d seconds.\n',floor(toc/60),round(rem(toc,60)));

	% word_set = unique(word_set);
	% disp(['There are ' num2str(length(word_set)) ' total words in this data!']);

	% X = zeros(length(keys(work_freq_map)),length(word_set));

	% works = keys(work_freq_map);
	% for i = 1:length(works)
	% 	current_work  = work_freq_map(works{i});
	% 	words_in_work = keys(current_work);
	% 	for j = 1:length(words_in_work)
	% 		index = 0;
	% 		for k = 1:length(word_set)
	% 			if strcmp(char(word_set(k)), words_in_work{j})
	% 				index = k;
	% 				break;
	% 			end
	% 		end
	% 		X(i,index) = current_work(words_in_work{j});
	% 	end
	% end

	Y 				 = transpose(authors_list);
	all_y_hat        = [];

	for i = 1:length(Y)														% Implement cross-validation:
		if i == 1
			model    = NaiveBayes.fit(X([i+1:end],:), ...
					   Y([i+1:end],:), 'Distribution', 'mn');
		elseif i == length(Y)
			model    = NaiveBayes.fit(X([1:i-1],:), ...
					   Y([1:i-1],:), 'Distribution', 'mn');
		else
			model    = NaiveBayes.fit(X([1:i-1,i+1:end],:), ...
					   Y([1:i-1,i+1:end],:), 'Distribution', 'mn');
		end
		y_hat        = model.predict(X(i,:));
		all_y_hat    = [all_y_hat, y_hat];
		% fprintf('Model predicted %s, Correct label was %s.\n', all_y_hat{i}, Y{i});
	end

	mistakes = 0;
	for i = 1:length(Y)														% Count # prediction mistakes.
		if  ~strcmp(Y(i), all_y_hat(i))
			mistakes = mistakes + 1;
		end
	end

	test_error       = mistakes / length(Y)
    fprintf('Algorithm completed in %d minutes and %d seconds.\n',floor(toc/60),round(rem(toc,60)));
end