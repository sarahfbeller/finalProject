function final_project(filename)
	clc; tic;																	% Clear variables and start stopwatch.
	addpath('libsvm-3.20/matlab');

	if (nargin > 1)	
		fprintf('Please enter a single input string.')
	elseif (nargin == 0)
	
		import javax.xml.xpath.*												% Get the xPath mechanism into the workspace.
		factory 		= XPathFactory.newInstance;
		xpath 			= factory.newXPath;

		input_directory = 'test/';
		noun_endings    = {'as' 'ou' 'an' 'a' 'ain' 'ai' 'wn' 'ais' 'hs' ...
							'h' 'hn' 'os' 'on' 'e' 'w' 'oin' 'ous' 'oi' 'ws' ...
							'us' 'uos' 'ui' 'un' 'u' 'ues' 'uwn' 'usi' 'is' ...
							'ews' 'ei' 'in' 'i' 'eis' 'ewn' 'esi' 'us'};
		verb_endings    = {'w' 'eis' 'ei' 'omen' 'ete' 'ousi' 'ousin' ...
							'wmen' 'hte' 'wsi' 'wsin' 'oimi' 'ois' 'oi' ...
							'oimen' 'oite' 'oien' 'etw' 'ontwn' 'wsan' 'ein' ...
							'wn' 'ousa' 'on' 'as' 'asa' 'an'};
		vowels 			= {'a' 'e' 'i' 'o' 'u' 'h' 'w'};
		prepositions 	= {'amfi' 'ana' 'aneu' 'anti' 'apo' 'dia' 'ein' 'eis' 'ek' ...
							'en' 'epi' 'ec' 'kata' 'meta' 'para' 'peri' 'plhn' ...
							'porrw' 'pro' 'pros' 'sun' 'xarin' 'uper' 'upo'};
		pronouns		= {'egw' 'emou' 'mou' 'emoi' 'moi' 'eme' 'me' ...				% personal pronouns
							'hmeis' 'hmwn' 'hmin' 'hmas' 'su' 'sou' ...	
							'soi' 'se' 'umeis' 'umwn' 'umin' 'umas' ...
							'outos' 'toutou' 'toutw' 'touton' 'outoi' 'toutwn' ...		% demonstratives
							'toutois' 'toutous' 'auth' 'tauths' 'tauth' 'tauthn' ...
							'autai' 'tautais' 'tautas' 'touto' 'tauta' ...
							'tis' 'tinos' 'tini' 'tina' 'tines' 'tinwn' ...				% tis/ti w/ accent	% indefinite
							'tisi' 'tisin' 'tinas' 'ti' 'tina' ...
							'os' 'ou' 'w' 'on' 'oi' 'ws' 'ois' 'ous' 'h' 'hs' ...		% relative
							'hn' 'ai' 'ais' 'as' 'o' 'ou' 'w' 'a'};
		articles 		= {'o' 'tou' 'tw' 'ton' 'oi' 'twn' 'tois' 'tous' 'h' ... 		% h/o just breathing; pronoun has accent too
							'ths' 'th' 'thn' 'ai' 'tais' 'tas' 'to' 'ta'};
		particles 		= {'an' 'ara' 'de' 'dh' 'ean' 'ews' 'gar' 'ge' 'men' 'mentoi' ...
							'mhn' 'mh' 'nh' 'ou' 'ouk' 'oukoun' 'oun' 'oux' 'te'};
		punctuation 	= {'.' ',' ';' ':' ''''};

		% ignored middle, passive, future, dual
		% ignored iota subscripts

		endings 		 = [noun_endings verb_endings];							% Combine noun and verb endings
		[dummy, index]   = sort(cellfun('size', endings, 2), 'descend');		% Order by size, largest to smallest.
	  	endings     	 = endings(index); 

		[token_list, authors_list] = deal({}, {});								% Initialize token & author lists.
		X                = zeros(0,0);											% Initialize X matrix.
		input_files      = dir(strcat(input_directory, '*.xml')); 				% Read only .xml files.
		file_num         = 1;

		[total_words, avg_words_per_line, avg_syllables_per_word, avg_word_length, ...
		 type_token_ratio, article_ratio, preposition_ratio, pronoun_ratio, ...
		 particle_ratio, avg_punctuation_per_line] = deal([], [], [], [], [], [], [], [], [], []);

		for file = input_files'													% For every file in the input directory:
			authors_list = [authors_list, strtok(file.name,'_')];				% Add this author to authors_list.
			file_path    = strcat(input_directory, file.name);
			xDoc 	     = xmlread(file_path);
			xmlwrite(xDoc);

			expression   = xpath.compile('TEI.2/text/body');					% Compile the xPath Expression.
			bodyNode     = expression.evaluate(xDoc, XPathConstants.NODE);		% Evaluate the xPath Expression.

			try
				text_body = char(bodyNode.getTextContent); 						% Returns Matlab string.
			catch exception
				fprintf('Unable to process %s.\n', file.name);					% If XML cannot be parsed.
				file_num = file_num - 1;										% Do not add to number of training files.
			end

			lines 	     = regexp(text_body, '\n', 'split'); 					% Split into lines.
			[m,n] 		 = size(X);
			X 			 = [X; zeros(1,n)];										% initialize X to count(tokens + extra features)

			[total_characters, total_syllables, total_words(file_num), unique_words, total_punctuation] = deal(0, 0, 0, 0, 0);

			for i = 1:length(lines) 											% For every line in the work:
				if isempty(lines{i})											% Skip empty lines.
					continue;
				end

				for ch = 1:length(lines{i})
					found = find(strcmp(lines{i}(ch), punctuation),1);
					if ~isempty(found) 												% Find punctuation.
						total_punctuation = total_punctuation + length(found);
					end
				end

				line = regexp(lines{i}, ' ', 'split');							% Split line into words.

				if ((length(line) == 1) && (line{1}(1) == '*'))					% Skip one-word lines (i.e. speakers).
					continue;
				end
				for j = 1:length(line) 											% For every word in the line:
					if (isempty(line{j}) || (line{j}(1) == '*'))				% Skip empty or capital words.
						continue;
					end
					
					if (nnz(strcmp(line{j}(1), {'o(\', 'h(\'})) ~= 0) 			% Pronouns with distinctive accents
						if length(pronoun_ratio) >= file_num
							pronoun_ratio(file_num) = pronoun_ratio(file_num) + 1;
						else
							pronoun_ratio(file_num) = 1;
						end
					end
					if (nnz(strcmp(line{j}(1), {'o(', 'h('})) ~= 0) 			% Articles with distinctive accents
						if length(article_ratio) >= file_num
							article_ratio(file_num) = article_ratio(file_num) + 1;
						else
							article_ratio(file_num) = 1;
						end
					end

					line{j} = regexprep(line{j},'[\/\\=|,.:;'']','');					% Take out accents.

					% Fix elided words (words that lose their final vowel before a word starting with a vowel)
					if (nnz(strcmp(line{j}, {'q', 'meq', 'kaq'})) ~= 0) 							% 't' becomes 'q' before a rough breathing
						line{j}(end) = 't';
					end
					if (nnz(strcmp(line{j}, {'ef', 'af'})) ~= 0) 									% 'p' becomes 'f' before a rough breathing
						line{j}(end) = 'p';
					end

					if (nnz(strcmp(line{j}, {'d', 't', 'od', 'g', 'm', 's'})) ~= 0)					% Words that should end in 'e'
						line{j} = line{j} + 'e';
					end

					if (nnz(strcmp(line{j}, {'kat', 'met', 'par', 'all', 'ar', 'di', 'an'})) ~= 0) % Words that should end in 'a'
						line{j} = line{j} + 'a';
					end

					if (nnz(strcmp(line{j}, {'ap', 'up'})) ~= 0) 									% Words that should end in 'o'
						line{j} = line{j} + 'o';
					end

					if (nnz(strcmp(line{j}, {'ep', 'amf'})) ~= 0) 									% Words that should end in 'i'
						line{j} = line{j} + 'i';
					end

					total_characters = total_characters + length(line{j});

					if ~isempty(find(strcmp(line{j}, prepositions),1))			% Check if word is a preposition.
						if length(preposition_ratio) >= file_num
							preposition_ratio(file_num) = preposition_ratio(file_num) + 1;
						else
							preposition_ratio(file_num) = 1;
						end
					end

					if ~isempty(find(strcmp(line{j}, particles),1))				% Check if word is a particle.
						if length(particle_ratio) >= file_num
							particle_ratio(file_num) = particle_ratio(file_num) + 1;
						else
							particle_ratio(file_num) = 1;
						end
					end

					if ~isempty(find(strcmp(line{j}, pronouns),1))				% Check if word is a pronoun.
						if length(pronoun_ratio) >= file_num
							pronoun_ratio(file_num) = pronoun_ratio(file_num) + 1;
						else
							pronoun_ratio(file_num) = 1;
						end
					end

					if ~isempty(find(strcmp(line{j}, articles),1))				% Check if word is a article.
						if length(article_ratio) >= file_num
							article_ratio(file_num) = article_ratio(file_num) + 1;
						else
							article_ratio(file_num) = 1;
						end
					end

					prev_vowel = false;											% Calculate number of syllables.
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

					if isempty(find(strcmp(line{j}, [articles prepositions pronouns particles]),1)) 		% Stem if noun/verb (primitive test)
						for k = length(endings{1}) : -1 : length(endings{end})  % Stem word.
							if length(line{j}) > k
								if ~isempty(find(strcmp(line{j}(end-k+1:end), endings),1))
									if(length(line{j}(1:end-k)) > 3)			% Don't truncate particles.
										line{j} = line{j}(1:end-k);
										break;
									end
								end
							end
						end
					end

					index = find(strcmp(line{j}, token_list));				% Find word in token_list.
					if isempty(index)										% If word is a new word:
						token_list = [token_list, line{j}]; 				% Add word to token_list.
						X(file_num, length(token_list)) = 1;  		 		% Add '1' to X matrix.
					else
						X(file_num, index) = X(file_num, index) + 1; 		% Increment training matrix.
					end
				end

				if length(total_words) >= file_num
					total_words(file_num) = total_words(file_num) + length(line);
				else
					total_words(file_num) = length(line);
				end
			end

			% Multiply to get 3 significant figures for all features.
			avg_words_per_line(file_num) 		= round((total_words(file_num) / length(lines))*100);		% Round because mn requires integers.
			avg_syllables_per_word(file_num) 	= round((total_syllables / total_words(file_num))*100);
			avg_word_length(file_num) 			= round((total_characters / total_words(file_num))*100);
			avg_punctuation_per_line(file_num) 	= round((total_punctuation / total_words(file_num))*1000);
			type_token_ratio(file_num) 			= round((length(find(X(file_num, :))) / total_words(file_num))*1000); % Finds indices of non-zero elements.

			file_num = file_num + 1;
		end

		hapax_legomena_ratio = [];						% 'hapax legomenon' = a word that only occurs once in the entire corpus
		for column = 1:length(token_list)
			found = find(X(:, column));
			if (length(found) == 1) && (X(found(1), column) == 1)										
				if length(hapax_legomena_ratio) >= found(1)
					hapax_legomena_ratio(found(1)) = hapax_legomena_ratio(found(1)) + 1;
				else
					hapax_legomena_ratio(found(1)) = 1;
				end
			end
		end

		% Multiply to get 3 significant figures for all features.
		hapax_legomena_ratio 	= round((hapax_legomena_ratio ./ total_words)*1000);
		preposition_ratio    	= round((preposition_ratio 	./ total_words)*10000);
		particle_ratio 			= round((particle_ratio ./ total_words)*10000);
		pronoun_ratio 			= round((pronoun_ratio ./ total_words)*10000);
		article_ratio 			= round((article_ratio ./ total_words)*10000);

		for i = 1:length(authors_list)
        	Y(i,1) = double(find(strcmp(authors_list{i}, unique(authors_list))));
    	end

    	words_in_corpus = length(X);
		X = double([X avg_words_per_line' avg_syllables_per_word' ...				% Add lexical features to X matrix.
			avg_word_length' type_token_ratio' hapax_legomena_ratio' ...
			preposition_ratio' particle_ratio' pronoun_ratio' article_ratio' ...
			avg_punctuation_per_line']);

		save(strcat(num2str(file_num-1),'training_matrices'), 'X', 'Y', 'words_in_corpus');						% Save variables for future use.
		if (floor(toc/60) == 0)
			fprintf('Finished analyzing %d works in %d seconds.\n', file_num-1,round(rem(toc,60)));
		else
			fprintf('Finished analyzing %d works in %d minutes and %d seconds.\n', file_num-1, floor(toc/60),round(rem(toc,60)));
		end
		fprintf('X,Y variables saved as %s.', strcat(num2str(file_num-1),'training_matrices.mat'));

	else 
		load(filename);
		fprintf('Data loaded from %s\n', filename);
	end


% Training & predicting part

	% Find indices of most common words:
	A = sum(X(:,1:words_in_corpus));
	[sortedValues, sortIndex] = sort(A(:),'descend');
	maxIndex25 = sortIndex(1:25)';
	maxIndex50 = sortIndex(1:50)';
	maxIndex100 = sortIndex(1:100)';
	maxIndex200 = sortIndex(1:200)';
	maxIndex500 = sortIndex(1:500)';
	% token_list(maxIndex100)

	feature_names 	= {'All features', 'All Words', '25 Most Common Words', '50 Most Common Words', '100 Most Common Words', ...
					 	'200 Most Common Words', '500 Most Common Words', 'Words/Line', 'Syllables/Word', 'Word Length', ...
					 	'Type Token Ratio', 'Hapax Legomena', 'Preposition Ratio', 'Particle Ratio', 'Pronoun Ratio', ...
					 	'Article Ratio', 'Punctuation/Line', '25&Lex', '50&Lex', '100&Lex', '200&Lex', '500&Lex', 'lex_features'};
	word_features 	= [2:7];
	lex_features 	= [8:17];
	feature_cols 	= {[1:length(X)],[1:words_in_corpus], maxIndex25, maxIndex50, maxIndex100, maxIndex200, maxIndex500, ...
						[words_in_corpus+1], [words_in_corpus+2], [words_in_corpus+3], [words_in_corpus+4], [words_in_corpus+5], ...
						[words_in_corpus+6], [words_in_corpus+7], [words_in_corpus+8], [words_in_corpus+9], [words_in_corpus+10],...
						[maxIndex25 lex_features], [maxIndex50 lex_features], [maxIndex100 lex_features], [maxIndex200 lex_features], ...
						[maxIndex500 lex_features], [words_in_corpus:words_in_corpus+length(lex_features)]};
    models  		= {'Naive Bayes', 'SVM', 'KNN', 'Decision Tree'};%, 'TreeBagger'};
    results 		= [];
    model_error 	= [];

    for i = 1:length(feature_names)

    	feature_X = X(:,feature_cols{i});

	    for j = 1:length(Y)															% Implement cross-validation:

	    	[X_train, Y_train, X_test, Y_test] = deal(removerows(feature_X,'ind',[j]), removerows(Y,'ind',[j]), feature_X(j,:), Y(j));

			for k = 1:length(models)
	        	results(j,i,k) = train_predict(X_train, Y_train, X_test, Y_test, k);
	        end

	    	% [X_train, Y_train, X_test, Y_test] = deal(removerows(X,'ind',[j]), removerows(Y,'ind',[j]), X(j,:), Y(j));
	        % bay_model = NaiveBayes.fit(X_train, Y_train, 'Distribution','mn');
			% svm_model = svmtrain(Y_train, X_train, '-q');
			% knn_model = ClassificationKNN.fit(X_train, Y_train);
			% dct_model = ClassificationTree.fit(X_train, Y_train);
			% tbr_model = TreeBagger(10, X_train, Y_train);

	        % results = [results; train_predict(X_train, Y_train, X_test, 1) ...%bay_model.predict(X(i,:)) ...
	        % 					svmpredict(Y(i), X(i,:), svm_model, '-q') ...
	        % 					knn_model.predict(X(i,:)) ...
	        % 					dct_model.predict(X(i,:))];% ...
	        					%double(nominal(tbr_model.predict(X(i,:))))];	% Predict on all the models.
			% mnr_model = mnrfit(removerows(X,'ind',[i]), ...
	  		%                    removerows(Y,'ind',[i]));             			% Train MNR model.
	        % mnr_result = mnrval(mnr_model, X(i,:));
	        % index = find(mnr_result == max(mnr_result(:)));
	        % Y(index)
	        % Y(i)
	        % mnr_results = [mnr_results; Y(index)];

	        % lda_model = ClassificationDiscriminant.fit(...
	                    % removerows(X,'ind',[i]), removerows(Y,'ind',[i]), ...
	                    % 'discrimType','pseudolinear');                            % Train Linear Discriminant model.
	        % qda_model = ClassificationDiscriminant.fit(...
	        %             removerows(X,'ind',[i]), removerows(Y,'ind',[i]), ...
	        %             'discrimType','pseudoquadratic');                         % Train Quadratic Discriminant model.

	        % lda_results = [lda_results; lda_model.predict(X(i,:))];               % Predict using LDA model.
	        % qda_results = [qda_results qda_model.predict(X(i,:))];                % Predict using QDA model.
	    end
	    
	    % fprintf('\n\nTest errors training on %s:', feature_names{i});
	    % for j = 1:length(models)													% Calculate & print out errors.
	    % 	model_error = 1 - (nnz(Y == results(:,j))  / length(Y));
	    % 	fprintf('\nModeling using %s: %.2f', models{j}, model_error);			
	    % end
	end

	for i = 1:length(feature_names)
		% fprintf('\n\nTest errors training on %s:', feature_names{i});
		for k = 1:length(models)													% Calculate & print out errors.
		    model_error(k,i) = 1 - (nnz(Y == results(:,i,k))  / length(Y));
		    % fprintf('\nModeling using %s: %.2f', models{k}, model_error(k,i));			
		end
	end

	importance = 1-abs(bsxfun(@minus,model_error(:,1),model_error(:,2:end)))';
	%importance = abs(bsxfun(@ldivide,model_error(:,1),model_error(:,2:end)))'

	% Plots

	% Plot no. works of author vs. total words of author or avg. words in author's work.
	% Train all lexgraphical features.

	h1 = figure(1);
    set(h1, 'Visible', 'off');
    bar(1-model_error(:,1));
    set(gca,'XTickLabel', models);
    ylim([0 1.2]);
    ylabel('% Accuracy');
    title('Plot of Overall Accuracy');
    plotfixer;
    print(h1,'-dpng','-r300','plots/01OverallAccuracy');

    h2 = figure(2);
    set(h2, 'Visible', 'off');
    suptitle('Plot of Feature Importance');    
    ax1 = subplot(2,1,1);
    ax2 = subplot(2,1,2);
    bar(ax1, importance(2:round((length([word_features lex_features])-1)/2),:));
    bar(ax2, importance(1+round((length([word_features lex_features])-1)/2):17,:));
    set(ax1,'XTickLabel', feature_names(2:round((length(feature_names)-1)/2)));
    set(ax2,'XTickLabel', feature_names(1+round((length(feature_names)-1)/2):17));
    set(ax1, 'YLim', [0 1.4]);
    set(ax2, 'YLim', [0 1.4]);
    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 1.8*length(feature_names(2:17)) 8]);
    legend(ax1,models); legend(ax2,models);
    plotfixer;
    print(h2,'-dpng','-r300','plots/02FeatureImportance');

    h3 = figure(3);
    set(h3, 'Visible', 'off');
    bar(1-model_error(:,word_features)');
    set(gca,'XTickLabel', feature_names(word_features));
    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 4.5*length(word_features) 6]);
    ylim([0 1.4]);
    ylabel('% Accuracy');
    legend(gca,models);
    title('Plot of Word Frequency Accuracy');
    plotfixer;
    print(h3,'-dpng','-r300','plots/03CommonWordAccuracies');

    h4 = figure(4);
    set(h4, 'Visible', 'off');
    suptitle('Plot of Lexographical Feature Accuracy');    
    ax1 = subplot(2,1,1);
    ax2 = subplot(2,1,2);
    bar(ax1, 1-model_error(:,lex_features(1:end/2))');
    bar(ax2, 1-model_error(:,lex_features(end/2+1:end))');
    set(ax1,'XTickLabel', feature_names(lex_features(1:end/2)));
    set(ax2,'XTickLabel', feature_names(lex_features(end/2+1:end)));
    set(ax1, 'YLim', [0 1.4]);
    set(ax2, 'YLim', [0 1.4]);
    ylabel(ax1, '% Accuracy');
    ylabel(ax2, '% Accuracy');
    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 1.8*length(lex_features) 8]);
    legend(ax1,models); legend(ax2,models);
    plotfixer;
    print(h4,'-dpng','-r300','plots/04LexFeatAcc');

    h5 = figure(5);
    set(h5, 'Visible', 'off');
    bar(1-model_error(:,18));
    set(gca,'XTickLabel', models);
    ylim([0 1.2]);
    ylabel('% Accuracy');
    title('Accuracy of Top 25 Words and Lexographical Features');
    plotfixer;
    print(h5,'-dpng','-r300','plots/05Top25&Lex');

    h6 = figure(6);
    set(h6, 'Visible', 'off');
    bar(1-model_error(:,19));
    set(gca,'XTickLabel', models);
    ylim([0 1.2]);
    ylabel('% Accuracy');
    title('Accuracy of Top 50 Words and Lexographical Features');
    plotfixer;
    print(h6,'-dpng','-r300','plots/06Top50&Lex');

    h7 = figure(7);
    set(h7, 'Visible', 'off');
    bar(1-model_error(:,20));
    set(gca,'XTickLabel', models);
    ylim([0 1.2]);
    ylabel('% Accuracy');
    title('Accuracy of Top 100 Words and Lexographical Features');
    plotfixer;
    print(h7,'-dpng','-r300','plots/07Top100&Lex');

    h8 = figure(8);
    set(h8, 'Visible', 'off');
    bar(1-model_error(:,21));
    set(gca,'XTickLabel', models);
    ylim([0 1.2]);
    ylabel('% Accuracy');
    title('Accuracy of Top 200 Words and Lexographical Features');
    plotfixer;
    print(h8,'-dpng','-r300','plots/08Top200&Lex');

    h9 = figure(9);
    set(h9, 'Visible', 'off');
    bar(1-model_error(:,22));
    set(gca,'XTickLabel', models);
    ylim([0 1.2]);
    ylabel('% Accuracy');
    title('Accuracy of Top 500 Words and Lexographical Features');
    plotfixer;
    print(h9,'-dpng','-r300','plots/09Top500&Lex');

    h10 = figure(10);
    set(h10, 'Visible', 'off');
    bar(1-model_error(:,23));
    set(gca,'XTickLabel', models);
    ylim([0 1.2]);
    ylabel('% Accuracy');
    title('Accuracy of Lexographical Features');
    plotfixer;
    print(h10,'-dpng','-r300','plots/10Lex');

    if (floor(toc/60) == 0)
    	fprintf('\n\nProgram executed in %d seconds.\n', round(rem(toc,60)));
    else 
    	fprintf('\n\nProgram executed in %d minutes and %d seconds.\n', floor(toc/60), round(rem(toc,60)));
    end

    function result = train_predict(X_train, Y_train, X_test, Y_test, m)
    	switch m
    		case 1
    			bay_model 	= NaiveBayes.fit(X_train, Y_train, 'Distribution','mn');
    			result 		= bay_model.predict(X_test);
    		case 2
    			svm_model 	= svmtrain(X_train, Y_train, '-q');
    			result 		= svmpredict(Y_test, X_test, svm_model, '-q');
    		case 3
				knn_model 	= ClassificationKNN.fit(X_train, Y_train);
				result 		= knn_model.predict(X_test);
			case 4
				dct_model 	= ClassificationTree.fit(X_train, Y_train);
				result 		= dct_model.predict(X_test);
    	end
    end

    function plotfixer;
        %Plot Fixer
        %Written by: Matt Svrcek  12/05/2001

        %Run this script after generating the raw plots.  It will find
        %all open figures and adjust line sizes and text properties.

        %Change the following values to suit your preferences.  The variable
        %names and comments that follow explain what each does and their options.

        plotlsize = 2; %thickness of plotted lines, in points
        axislsize = 1.5; %thickness of tick marks and borders, in points
        markersize = 8;  %size of line markers, default is 6

        %font names below must exactly match your system's font names
        %check the list in the figure pull down menu under Tools->Text Properties
        %note, the script editor does not have all the fonts, so use the figure menu

        axisfont = 'Helvetica'; %changes appearance of axis numbers
        axisfontsize = 16;            %in points
        axisfontweight = 'normal';    %options are 'light' 'normal' 'demi' 'bold' 
        axisfontitalics = 'normal';   %options are 'normal' 'italic' 'oblique'

        legendfont = 'Helvetica'; %changes text in the legend
        legendfontsize = 14;
        legendfontweight = 'normal';
        legendfontitalics = 'normal';

        labelfont = 'Helvetica';  %changes x, y, and z axis labels
        labelfontsize = 16;  
        labelfontweight = 'normal'; 
        labelfontitalics = 'normal';

        titlefont = 'Helvetica';  %changes title
        titlefontsize = 18;
        titlefontweight = 'normal';
        titlefontitalics = 'normal';

        textfont = 'Helvetica';   %changes text
        textfontsize = 14;
        textfontweight = 'normal';
        textfontitalics = 'normal';

        %stop changing things below this line
        %----------------------------------------------------
        axesh = findobj('Type', 'axes');
        legendh = findobj('Tag', 'legend');
        lineh = findobj(axesh, 'Type', 'line');
        axestexth = findobj(axesh, 'Type', 'text');

        set(lineh, 'LineWidth', plotlsize)
        set(lineh, 'MarkerSize', markersize)
        set(axesh, 'LineWidth', axislsize)
        set(axesh, 'FontName', axisfont)
        set(axesh, 'FontSize', axisfontsize)
        set(axesh, 'FontWeight', axisfontweight)
        set(axesh, 'FontAngle', axisfontitalics)
        set(axestexth, 'FontName', textfont)
        set(axestexth, 'FontSize', textfontsize)
        set(axestexth, 'FontWeight', textfontweight)
        set(axesh, 'Box','on')
        for(i = 1:1:size(axesh))
           legend(axesh(i))
           set(get(gca,'XLabel'), 'FontName', labelfont)
           set(get(gca,'XLabel'), 'FontSize', labelfontsize)
           set(get(gca,'XLabel'), 'FontWeight', labelfontweight)
           set(get(gca,'XLabel'), 'FontAngle', labelfontitalics)
           set(get(gca,'YLabel'), 'FontName', labelfont)
           set(get(gca,'YLabel'), 'FontSize', labelfontsize)
           set(get(gca,'YLabel'), 'FontWeight', labelfontweight)
           set(get(gca,'YLabel'), 'FontAngle', labelfontitalics)
           set(get(gca,'ZLabel'), 'FontName', labelfont)
           set(get(gca,'ZLabel'), 'FontSize', labelfontsize)
           set(get(gca,'ZLabel'), 'FontWeight', labelfontweight)
           set(get(gca,'ZLabel'), 'FontAngle', labelfontitalics)
           set(get(gca,'Title'), 'FontName', titlefont)
           set(get(gca,'Title'), 'FontSize', titlefontsize)
           set(get(gca,'Title'), 'FontWeight', titlefontweight)
           set(get(gca,'Title'), 'FontAngle', titlefontitalics)
        end
    end

end