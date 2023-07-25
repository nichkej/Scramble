//
//  APIReader.swift
//  Scramble
//
//  Created by Nikola Jovicevic on 9.7.23..
//

import Foundation

struct APIReader {
    func getJSON(urlString: String, completion: @escaping ([DictionaryWord]?) -> Void) {
        guard let url = URL(string: urlString) else {
            return
        }
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let data = data else {
                return
            }
            let decoder = JSONDecoder()
            guard let decodedData = try? decoder.decode([DictionaryWord].self, from: data) else {
                return
            }
            completion(decodedData)
        }.resume()
    }
}
