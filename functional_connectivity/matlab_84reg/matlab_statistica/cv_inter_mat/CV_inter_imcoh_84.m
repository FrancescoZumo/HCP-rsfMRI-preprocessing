function [CV_inter_1200_matrix, CV_inter_retest_matrix, CV_inter_matrix] = CV_inter_imcoh_84(voxels)
% Calcola il Coeffient of Variation secondo la formula presente
% nel paper "On the Viability of Diffusion MRI-Based Microstructural Biomarkers
% in Ischemic Stroke" di Boscolo Galazzo et al. (2018)

n_soggetti = 45;
lista_soggetti = string(readmatrix('soggetti46.txt'));
s_volumes = '800';

% Facciamo sul 1200 (Test)
CV_inter_1200_matrix = zeros(voxels);
media_CVinter_array = zeros(1,n_soggetti);
sig_array = zeros(1,n_soggetti);
for i = 1:voxels
    for k = 1:i
        for m = 1:n_soggetti
            % Carico soggetto s1200
            img_coherency_matrix_s1200_val_abs_zero_norm = conn_measures.s_1200{m}.img_coherency_matrix_s1200_val_abs_zero_norm;
            % Vettore che serve per l'overall mean
            media_CVinter_array(1,m) = img_coherency_matrix_s1200_val_abs_zero_norm(i,k);
            % Calcolo per varianza inter-soggetto (sigma_ws)
            sig_array(1,m) = img_coherency_matrix_s1200_val_abs_zero_norm(i,k);
        end
        CV_inter_1200_matrix(i,k) = (std(sig_array) / mean(media_CVinter_array))*100;
    end
end

% Facciamo sul Retest
CV_inter_retest_matrix = zeros(voxels);
media_CVinter_array = zeros(1,n_soggetti);
sig_array = zeros(1,n_soggetti);
for i = 1:voxels
    for k = 1:i
        for m = 1:n_soggetti
            % Carico soggetto sretest che uso per overall mean
            img_coherency_matrix_sretest_val_abs_zero_norm = conn_measures.s_retest{m}.img_coherency_matrix_sretest_val_abs_zero_norm;
            % Vettore che serve per l'overall mean
            media_CVinter_array(1,m) = img_coherency_matrix_sretest_val_abs_zero_norm(i,k);
            % Calcolo per varianza inter-soggetto (sigma_ws)
            sig_array(1,m) = img_coherency_matrix_sretest_val_abs_zero_norm(i,k);
        end
        CV_inter_retest_matrix(i,k) = (std(sig_array) / mean(media_CVinter_array))*100;
    end
end

% Facciamo la media delle due 
CV_inter_matrix = (CV_inter_1200_matrix + CV_inter_retest_matrix)/2;