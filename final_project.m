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
	vowels = {'a' 'e' 'i' 'o' 'u' 'h' 'w'};
	% s and then verb ending -> cut s
	% ignored middle and passive
	% ignored iota subscripts with a, h, w

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

	avg_words_per_line = [];										
	avg_syllables_per_word = [];											% Syllable = count(non-consecutive vowels)
	avg_word_length = [];													% Before stemming
	type_token_ratio = [];													% |Vocabulary| / num(tokens)

	for file = input_files'													% For every file in the input directory:
		authors_list = [authors_list, strtok(file.name,'_')];				% Get this author to author_list.
		file_path    = strcat(input_directory, file.name);
		xDoc 	     = xmlread(file_path);
		xmlwrite(xDoc);

		expression   = xpath.compile('TEI.2/text/body');					% Compile the xPath Expression.
		bodyNode     = expression.evaluate(xDoc, XPathConstants.NODE);		% Evaluate the xPath Expression.

		try
			text_body = char(bodyNode.getTextContent); 						% Returns Matlab string.
		catch exception
			fprintf('Unable to process %s.\n', file.name);
			file_num = file_num - 1;										% Do not add to number of training files.
		end

		lines 	     = regexp(text_body, '\n', 'split'); 					% Split into lines.
		lines        = regexprep(lines,'[\/\\=|,.:]','');					% Take out accents.

		[m,n] 		 = size(X);
		X 			 = [X; zeros(1,n)];										% initialize X to count(tokens + extra features)

		total_characters = 0;
		total_syllables = 0;
		total_words = 0;
		unique_words = 0;

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

					total_characters = total_characters + length(line{j});

					prev_vowel = false;										% Calculate number of syllables.
					for m = 1:length(line{j})
						if ~isempty(find(strcmp(line{j}(m), vowels),1))
							if ~prev_vowel
								total_syllables = total_syllables + 1;
								prev_vowel = true;
							end
						else
							prev_vowel = false;
						end
					end

					for k = length(endings{1}) : -1 : length(endings{end})  % Stem word.
						if length(line{j}) > k
							if ~isempty(find(strcmp(line{j}(end-k+1:end), endings),1))
								if(length(line{j}(1:end-k)) > 1)			% Don't truncate particles.
									line{j} = line{j}(1:end-k);
									break;
								end
							end
						end
					end

					index = find(strcmp(line{j}, token_list));				% Find word in token_list.
					if isempty(index)										% If word is a new word:
						token_list = [token_list, line{j}]; 				% Add word to token list.
						X(file_num, length(token_list)) = 1;  		 		% Add '1' to X matrix.
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
				total_words = total_words + length(line);
			end
		end
		% work_freq_map(file.name) = word_freq_map;
		avg_words_per_line(file_num) = round(total_words/length(lines));		% Round because mn requires integers.
		avg_syllables_per_word(file_num) = round(total_syllables/total_words);
		avg_word_length(file_num) = round(total_characters/total_words);

		non_zero_set = find(X(file_num, :));									% Makes array of indices of non-zero elements
		type_token_ratio(file_num) = round(length(non_zero_set)/total_words);
		file_num = file_num + 1;
	end

	% 'hapax legomena' = a word that only occurs once in the entire corpus
	hapax_legomena = [];
	for column = 1:length(token_list)
		found = find(X(:, column));
		if length(found) == 1 													% Word only in 1 work in corpus
			if X(found(1), column) == 1 										% Only 1 occurrence of the word in the work
				if length(hapax_legomena) >= found(1)
					hapax_legomena(found(1)) = hapax_legomena(found(1)) + 1;
				else
					hapax_legomena(found(1)) = 1;
				end
			end
		end
	end

	% Add sentence features to X matrix.
	X = [X avg_words_per_line' avg_syllables_per_word' avg_word_length' type_token_ratio' hapax_legomena'];

	save(strcat(num2str(file_num-1),'training_matrix'), 'X');					% Save X matrix for future use.
	fprintf('Finished training in %d minutes and %d seconds.\n', floor(toc/60),round(rem(toc,60)));
	fprintf('Training matrix populated using %d Ancient Greek works.', file_num-1);

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
	bay_results      = [];
	% lda_results      = [];
	% qda_results      = [];
	% mnr_results		 = [];

	for i = 1:length(Y)														% Implement cross-validation:
		
		bay_model    = NaiveBayes.fit(removerows(X,'ind',[i]), ...
					   removerows(Y,'ind',[i]), 'Distribution','mn');		% Train Naive Bayes model.

		% lda_model    = ClassificationDiscriminant.fit(...
		% 			   removerows(X,'ind',[i]), removerows(Y,'ind',[i]), ...
		% 			   'discrimType','pseudolinear');						% Train Linear Discriminant model.

		% qda_model    = ClassificationDiscriminant.fit(...
		% 			   removerows(X,'ind',[i]), removerows(Y,'ind',[i]), ...
		% 			   'discrimType','pseudoquadratic');					% Train Quadratic Discriminant model.

		bay_results  = [bay_results bay_model.predict(X(i,:))];				% Predict using Naive Bayes model.
		% lda_results  = [lda_results lda_model.predict(X(i,:))];				% Predict using LDA model.
		% qda_results  = [qda_results qda_model.predict(X(i,:))];			% Predict using QDA model.

		% mnr_results   = [mnr_results, mnr_model.predict(X(i,:))];
	end

	% lda_results  	 = classify(X,X,Y);


	bay_error 		 = length(setdiff(Y, bay_results)) / length(Y);
	% lda_error 		 = length(setdiff(Y, lda_results)) / length(Y);
	% qda_error 		 = length(setdiff(Y, qda_results)) / length(Y);
	% mnr_error = nnz(categorical(Y) == categorical(mnr_results)) / length(Y);

	fprintf('\n\nTest error using Naive Bayes algorithm: %.2f\n', bay_error);
	% fprintf('Test error using Linear Discriminant analysis: %.2f\n', lda_error);
	% fprintf('Test error using Quadratic Discriminant analysis: %.2f\n', qda_error);

	% fprintf('Test error using Multinomial Regression algorithm: %f', mnr_error);
    fprintf('\nProgram executed in %d minutes and %d seconds.\n', floor(toc/60),round(rem(toc,60)));
end